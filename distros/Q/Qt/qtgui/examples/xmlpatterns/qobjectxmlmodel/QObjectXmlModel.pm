package QObjectXmlModel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtXmlPatterns4;
use QtCore4::isa qw( Qt::SimpleXmlNodeModel );
use List::MoreUtils qw( first_index any );

=begin

 * @short Delegates QtCore's Qt::Object into Patternist's Qt::AbstractXmlNodeModel.
 * known as pre/post numbering.
 *
 * Qt::ObjectXmlModel sets the toggle on Qt::XmlNodeModelIndex to @c true, if it
 * represents a property of the Qt::Object. That is, if the Qt::XmlNodeModelIndex is
 * an attribute.
 *
 * @author Frans Englich <frans.englich@nokia.com>

=cut


    # The highest three bits are used to signify whether the node index
    # is an artificial node.
    #
    # @short if Qt::XmlNodeModelIndex::additionalData() has the
    # QObjectProperty flag set, then the Qt::XmlNodeModelIndex is an
    # attribute of the Qt::Object element, and the remaining bits form
    # an offset to the Qt::Object property that the Qt::XmlNodeModelIndex
    # refers to.

use constant
{
    IsQObject               => 0,
    QObjectProperty         => 1 << 26,
    MetaObjects             => 2 << 26,
    MetaObject              => 3 << 26,
    MetaObjectClassName     => 4 << 26,
    MetaObjectSuperClass    => 5 << 26,
    QObjectClassName        => 6 << 26
};

sub m_baseURI() {
    return this->{m_baseURI};
}

sub m_root() {
    return this->{m_root};
}

sub m_allMetaObjects() {
    return this->{m_allMetaObjects};
}

    #const Qt::Url              m_baseURI;
    #Qt::Object *const          m_root;
    #const AllMetaObjects    m_allMetaObjects;

#<metaObjects>
#    <metaObject className='Qt::Object'/>
#    <metaObject className='Qt::Widget' superClass='Qt::Object'>
#    </metaObject>
#    ...
#</metaObjects>
#<Qt::Object objectName='MyWidget' property1='...' property2='...'> <!-- This is root() -->
#    <Qt::Object objectName='MyFOO' property1='...'/>
#    ....
#</Qt::Object>

sub NEW {
    my ($class, $object, $np) = @_;
    $class->SUPER::NEW($np);
    this->{m_baseURI} = Qt::Url::fromLocalFile(Qt::CoreApplication::applicationFilePath());
    this->{m_root} = $object;
    this->{m_allMetaObjects} = allMetaObjects();
    die 'Base directory not valid' unless m_baseURI->isValid();
}

# [5]
sub qObjectSibling
{
    my ($pos, $n) = @_;
    die "Invalid value for \$pos: $pos" unless ($pos == 1 || $pos == -1);
    die '$n is not a QObject' unless (asQObject($n));

    my $parent = asQObject($n)->parent();
    if ($parent) {
        my $children = $parent->children();
        my $siblingPos = ( first_index { $_->Qt::base::getPointer() == asQObject($n)->Qt::base::getPointer() } @{$children} ) + $pos;

        if ($siblingPos >= 0 && $siblingPos < scalar @{$children}) {
            return createIndex($children->[$siblingPos]);
        }
        else {
            return Qt::XmlNodeModelIndex();
        }
    }
    else {
        return Qt::XmlNodeModelIndex();
    }
}
# [5]

# [1]
sub toNodeType
{
    my ($n) = @_;
    return $n->additionalData() & (15 << 26);
}
# [1]

# [9]
sub allMetaObjects
{
    my $query = Qt::XmlQuery(namePool());
    $query->bindVariable('root', Qt::XmlItem(root()));
    $query->setQuery('declare variable $root external;' .
                   '$root/descendant-or-self::QObject');
    $query->isValid() or die 'Invalid query';

    my $result = Qt::XmlResultItems();
    $query->evaluateTo($result);
    my $i = $result->next();

    my @objects;
    while (!$i->isNull()) {
        my $moo = asQObject($i->toNodeModelIndex())->metaObject();
        while ($moo) {
            if (! any{ $_->Qt::base::getPointer() == $moo->Qt::base::getPointer() } @objects ) {
                push @objects, $moo;
            }
            $moo = $moo->superClass();
        }
        $i = $result->next();
    }

    return \@objects;
}
# [9]

sub metaObjectSibling
{
    my ($pos, $n) = @_;
    ($pos == 1 || $pos == -1) or die "Invalid value for \$pos: $pos";
    !$n->isNull() or die "\$n cannot be null";

    my $indexOf = (first_index{ $_->Qt::base::getPointer() == $n->internalPointer()->Qt::base::getPointer() } @{m_allMetaObjects()}) + $pos;

    if ($indexOf >= 0 && $indexOf < scalar @{m_allMetaObjects()}) {
        #return createIndex(const_cast<Qt::MetaObject *>(m_allMetaObjects.at(indexOf)), MetaObject);
        return createIndex(m_allMetaObjects->[$indexOf], MetaObject);
    }
    else {
        return Qt::XmlNodeModelIndex();
    }
}

# [2]
sub nextFromSimpleAxis
{
    my ($axis, $n) = @_;
    my $nodeType = toNodeType($n);
    if ($nodeType == IsQObject) {
        if ( $axis == Qt::AbstractXmlNodeModel::Parent() ) {
            return createIndex(asQObject($n)->parent());
        }
        elsif ( $axis == Qt::AbstractXmlNodeModel::FirstChild() ) {
            if (!asQObject($n) || !scalar @{asQObject($n)->children()}) {
                return Qt::XmlNodeModelIndex();
            }
            else {
                return createIndex(asQObject($n)->children()->[0]);
            }
        }
        elsif ( $axis == Qt::AbstractXmlNodeModel::NextSibling() ) {
            return qObjectSibling(1, $n);
        }

# [10]
        elsif ( $axis == Qt::AbstractXmlNodeModel::PreviousSibling() ) {
            if (asQObject($n) == m_root) {
                return createIndex(0, MetaObjects);
            }
            else {
                return qObjectSibling(-1, $n);
            }
        }
# [10]
        die 'Don\'t get here';
    }

# [7]
    elsif ( $nodeType == QObjectClassName || $nodeType == QObjectProperty ) {
        $axis == Qt::AbstractXmlNodeModel::Parent() or die "\$axis must be 'Qt::AbstractXmlNodeModel::Parent()'";
        return createIndex(asQObject($n));
    }
# [7]
# [2]
# [3]

# [11]
    elsif ( $nodeType == MetaObjects ) {
        if ( $axis == Qt::AbstractXmlNodeModel::Parent() ) {
            return Qt::XmlNodeModelIndex();
        }
        if ( $axis == Qt::AbstractXmlNodeModel::PreviousSibling() ) {
            return Qt::XmlNodeModelIndex();
        }
        if ( $axis == Qt::AbstractXmlNodeModel::NextSibling() ) {
            return root();
        }
        if ( $axis == Qt::AbstractXmlNodeModel::FirstChild() ) {
            #return createIndex(const_cast<Qt::MetaObject*>(m_allMetaObjects.first()),MetaObject);
            return createIndex(m_allMetaObjects->[0],MetaObject);
        }
        die 'Don\'t get here';
    }
# [11]

    elsif ( $nodeType == MetaObject ) {
        if ( $axis == Qt::AbstractXmlNodeModel::FirstChild() ) {
            return Qt::XmlNodeModelIndex();
        }
        elsif ( $axis == Qt::AbstractXmlNodeModel::Parent() ) {
            return createIndex(0, MetaObjects);
        }
        elsif ( $axis == Qt::AbstractXmlNodeModel::PreviousSibling() ) {
            return metaObjectSibling(-1, $n);
        }
        elsif ( $axis == Qt::AbstractXmlNodeModel::NextSibling() ) {
            return metaObjectSibling(1, $n);
        }
    }

    elsif ( $nodeType == MetaObjectClassName || $nodeType == MetaObjectSuperClass ) {
        $axis == Qt::AbstractXmlNodeModel::Parent() or die "\$axis must be 'Qt::AbstractXmlNodeModel::Parent()'";
        return createIndex(asQObject($n), MetaObject);
    }
# [3]
# [4]

    return Qt::XmlNodeModelIndex();
}
# [4]

# [6]
sub attributes
{
    my ($n) = @_;
    my @result;
    my $object = asQObject($n);

    my $nodeType = toNodeType($n);
    if ( $nodeType == IsQObject ) {
        my $metaObject = $object->metaObject();
        my $count = $metaObject->propertyCount();
        push @result, createIndex($object, QObjectClassName);

        for (my $i = 0; $i < $count; ++$i) {
            my $qmp = Qt::MetaProperty($metaObject->property($i));
            my $ii = $metaObject->indexOfProperty($qmp->name());
            if ($i == $ii) {
                push @result, createIndex($object, QObjectProperty | $i);
            }
        }
        return \@result;
    }
# [6]
    elsif ( $nodeType == MetaObject ) {
        push @result, createIndex($object, MetaObjectClassName);
        push @result, createIndex($object, MetaObjectSuperClass);
        return \@result;
    }
# [8]
    else {
        return [];
    }
}
# [8]

sub asQObject
{
    my ($n) = @_;
    return $n->internalPointer();
}

sub isProperty
{
    my ($n) = @_;
    return $n->additionalData() & QObjectProperty;
}

sub documentUri
{
    return m_baseURI;
}

sub kind
{
    my ($n) = @_;
    my $nodeType = toNodeType($n);
    if ( $nodeType == IsQObject ||
         $nodeType == MetaObject ||
         $nodeType == MetaObjects ) {
        return Qt::XmlNodeModelIndex::Element();
    }
    elsif ( $nodeType == QObjectProperty ||
            $nodeType == MetaObjectClassName ||
            $nodeType == MetaObjectSuperClass ||
            $nodeType == QObjectClassName ) {
        return Qt::XmlNodeModelIndex::Attribute();
    }

    die 'Don\'t get here';
    return Qt::XmlNodeModelIndex::Element();
}

sub compareOrder
{
    return Qt::XmlNodeModelIndex::Follows(); # TODO
}

# [0]
sub root
{
    my ($n) = @_;
    if ( defined $n && $n->isa( 'Qt::XmlNodeModelIndex' ) ) {
        my $p = asQObject($n);
        defined $p or die;

        do {
            my $candidate = $p->parent();
            if (defined $candidate) {
                $p = $candidate;
            }
            else {
                last;
            }
        }
        while (1);

        return createIndex($p);
    }
    else {
        return createIndex(m_root);
    }
}
# [0]


# We simply throw all of them into a Qt::List and
# return an iterator over it.
sub ancestors
{
    my ($n) = @_;
    my $p = asQObject($n);
    defined $p or die;

    my @result;
    do {
        my $candidate = $p->parent();
        if (defined $candidate) {
            push @result, createIndex($candidate, 0);
            $p = $candidate;
        }
        else {
            last;
        }
    }
    while (1);

    return \@result;
}

sub toMetaProperty
{
    my ($n) = @_;
    my $propertyOffset = $n->additionalData() & (~QObjectProperty);
    my $qo = asQObject($n);
    return $qo->metaObject()->property($propertyOffset);
}

sub name
{
    my ($n) = @_;
    
    my $nodeType = toNodeType($n);
    if ( $nodeType == IsQObject ) {
        return Qt::XmlName(namePool(), 'QObject');
    }
    elsif ( $nodeType == MetaObject ) {
        return Qt::XmlName(namePool(), 'metaObject');
    }
    elsif ( $nodeType == QObjectClassName ||
            $nodeType == MetaObjectClassName ) {
        return Qt::XmlName(namePool(), 'className');
    }
    elsif ( $nodeType == QObjectProperty ) {
        return Qt::XmlName(namePool(), toMetaProperty($n)->name());
    }
    elsif ( $nodeType == MetaObjects ) {
        return Qt::XmlName(namePool(), 'metaObjects');
    }
    elsif ( $nodeType == MetaObjectSuperClass ) {
        return Qt::XmlName(namePool(), 'superClass');
    }

    die 'Don\'t get here';
    return Qt::XmlName();
}

sub typedValue
{
    my ($n) = @_;

    my $nodeType = toNodeType($n);
    if ( $nodeType == QObjectProperty ) {
        my $candidate = toMetaProperty($n)->read(asQObject($n));
        if (isTypeSupported($candidate->type())) {
            return $candidate;
        }
        else {
            return Qt::Variant();
        }
    }

    if ( $nodeType == MetaObjectClassName ) {
        return Qt::Variant(Qt::String($n->internalPointer()->className()));
    }

    if ( $nodeType == MetaObjectSuperClass ) {
        my $superClass = $n->internalPointer()->superClass();
        if ($superClass) {
            return Qt::Variant(Qt::String($superClass->className()));
        }
        else {
            return Qt::Variant();
        }
    }

    if ( $nodeType == QObjectClassName ) {
        return Qt::Variant(Qt::String(asQObject($n)->metaObject()->className()));
    }
    else {
        return Qt::Variant();
    }
}

#Returns \c true if Qt::Variants of type \a type can be used
#in QtXmlPatterns, otherwise \c false.
sub isTypeSupported
{
    my ($type) = @_;
    # See data/qatomicvalue.cpp too.
    # Fallthrough all these.
    if ( $type == Qt::Variant::Char() ||
         $type == Qt::Variant::String() ||
         $type == Qt::Variant::Url() ||
         $type == Qt::Variant::Bool() ||
         $type == Qt::Variant::ByteArray() ||
         $type == Qt::Variant::Int() ||
         $type == Qt::Variant::LongLong() ||
         $type == Qt::Variant::ULongLong() ||
         $type == Qt::Variant::Date() ||
         $type == Qt::Variant::DateTime() ||
         $type == Qt::Variant::Time() ||
         $type == Qt::Variant::Double() ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;
