package FileTree;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtXmlPatterns4;
use QtCore4::isa qw( Qt::SimpleXmlNodeModel );
use List::MoreUtils qw ( first_index );

use constant {
    File => 1,
    Directory => 2,
    AttributeFileName => 3,
    AttributeFilePath => 4,
    AttributeSize => 5,
    AttributeMIMEType => 6,
    AttributeSuffix => 7,
};

    #! [2]
    #mutable Qt::Vector<Qt::FileInfo>  m_fileInfos;
    #Qt::Dir::Filters         m_filterAllowAll;
    #Qt::Dir::SortFlags       m_sortFlags;
    #Qt::Vector<Qt::XmlName>           m_names;
sub m_fileInfos() {
    return this->{m_fileInfos};
}

sub m_filterAllowAll() {
    return this->{m_filterAllowAll};
}

sub m_sortFlags() {
    return this->{m_sortFlags};
}

sub m_names() {
    return this->{m_names};
}

=begin

The model has two types of nodes: elements & attributes.

    <directory name=''>
        <file name=''>
        </file>
    </directory>

  In Qt::XmlNodeModelIndex we store two values. Qt::XmlNodeIndex::data()
  is treated as a signed int, and it is an index into m_fileInfos
  unless it is -1, in which case it has no meaning and the value
  of Qt::XmlNodeModelIndex::additionalData() is a Type name instead.

  The constructor passes \a pool to the base class, then loads an
  internal vector with an instance of Qt::XmlName for each of the
  strings 'file', 'directory', 'fileName', 'filePath', 'size',
  'mimeType', and 'suffix'.

=cut

# [2]
sub NEW {
    my ($class, $pool) = @_;
    $class->SUPER::NEW($pool);
    this->{m_fileInfos} = [];
    this->{m_filterAllowAll} = (Qt::Dir::AllEntries() |
                     Qt::Dir::AllDirs() |
                     Qt::Dir::NoDotAndDotDot() |
                     Qt::Dir::Hidden()),
    this->{m_sortFlags} = Qt::Dir::Name();
    my $np = namePool();
    this->{m_names} = {
        File              , Qt::XmlName($np, 'file'),
        Directory         , Qt::XmlName($np, 'directory'),
        AttributeFileName , Qt::XmlName($np, 'fileName'),
        AttributeFilePath , Qt::XmlName($np, 'filePath'),
        AttributeSize     , Qt::XmlName($np, 'size'),
        AttributeMIMEType , Qt::XmlName($np, 'mimeType'),
        AttributeSuffix   , Qt::XmlName($np, 'suffix'),
    };
}
# [2]

=begin

  Returns the Qt::XmlNodeModelIndex for the model node representing
  the directory \a dirName.

  It calls Qt::Dir::cleanPath(), because an instance of Qt::FileInfo
  constructed for a path ending in '/' will return the empty string in
  fileName(), instead of the directory name.

=cut

sub nodeFor
{
    my ($dirName) = @_;
    my $dirInfo = Qt::FileInfo(Qt::Dir::cleanPath($dirName));
    die "Directory $dirName does not exist." unless $dirInfo->exists();
    return toNodeIndex($dirInfo);
}

=begin

  Since the value will always be in m_fileInfos, it is safe for
  us to return a reference to it.

=cut

# [6]
sub toFileInfo
{
    my ($nodeIndex) = @_;
    return m_fileInfos->[$nodeIndex->data()];
}
# [6]

=begin

  Returns the model node index for the node specified by the
  Qt::FileInfo and node Type.
  or
  Returns the model node index for the node specified by the
  Qt::FileInfo, which must be a  Type::File or Type::Directory.

=cut

# [1]
sub toNodeIndex
{
    my ($fileInfo, $attributeName) = @_;
    if ( !defined $attributeName ) {
        return toNodeIndex($fileInfo, $fileInfo->isDir() ? Directory : File);
    }
    my $indexOf = first_index { $_ == $fileInfo } @{m_fileInfos()};

    if ($indexOf == -1) {
        push @{m_fileInfos()}, $fileInfo;
        return createIndex( scalar @{m_fileInfos()}-1, $attributeName);
    }
    else {
        return createIndex($indexOf, $attributeName);
    }
}
# [1]

=begin

  This private helper function is only called by nextFromSimpleAxis().
  It is called whenever nextFromSimpleAxis() is called with an axis
  parameter of either \c{PreviousSibling} or \c{NextSibling}. 

=cut

# [5]
sub nextSibling
{
    my ($nodeIndex, $fileInfo, $offset) = @_;
    die "Offset must be -1 or 1" unless ($offset == -1 || $offset == 1);

    # Get the context node's parent.
    my $parent = Qt::XmlNodeModelIndex(nextFromSimpleAxis(Qt::AbstractXmlNodeModel::Parent(), $nodeIndex));

    if ($parent->isNull()) {
        return Qt::XmlNodeModelIndex();
    }

    # Get the parent's child list.
    my $parentFI = Qt::FileInfo(toFileInfo($parent));
    die "Parent's type must be 'Directory" unless $parent->additionalData() == Directory;
    my $siblings = Qt::Dir($parentFI->absoluteFilePath())->entryInfoList([],
                                                                         m_filterAllowAll,
                                                                         m_sortFlags);
    print STDERR 'Can\'t happen! We started at a child.' if (!defined $siblings || scalar @{$siblings} < 0);

    # Find the index of the child where we started.
    my $indexOfMe = first_index { $_ == $fileInfo } @{$siblings};

    # Apply the offset.
    my $siblingIndex = $indexOfMe + $offset;
    if ($siblingIndex < 0 || $siblingIndex > scalar @{$siblings} - 1) {
        return Qt::XmlNodeModelIndex();
    }
    else {
        return toNodeIndex($siblings->[$siblingIndex]);
    }
}
# [5]

=begin

  This function is called by the QtXmlPatterns query engine when it
  wants to move to the next node in the model. It moves along an \a
  axis, \e from the node specified by \a nodeIndex.

  This function is usually the one that requires the most design and
  implementation work, because the implementation depends on the
  perhaps unique structure of your non-XML data.

  There are \l {Qt::AbstractXmlNodeModel::SimpleAxis} {four values} for
  \a axis that the implementation must handle, but there are really
  only two axes, i.e., vertical and horizontal. Two of the four values
  specify direction on the vertical axis (\c{Parent} and
  \c{FirstChild}), and the other two values specify direction on the
  horizontal axis (\c{PreviousSibling} and \c{NextSibling}).

  The typical implementation will be a \c switch statement with
  a case for each of the four \a axis values.

=cut

# [4]
sub nextFromSimpleAxis
{
    my ($axis, $nodeIndex) = @_;
    my $fi = Qt::FileInfo(toFileInfo($nodeIndex));
    my $type = $nodeIndex->additionalData();

    if ($type != File && $type != Directory) {
        print STDERR 'An attribute only has a parent!' if $axis == Qt::AbstractXmlNodeModel::Parent();
        return toNodeIndex($fi, Directory);
    }

    if ( $axis == Qt::AbstractXmlNodeModel::Parent() ) {
        return toNodeIndex(Qt::FileInfo($fi->path()), Directory);
    }
    elsif ( $axis == Qt::AbstractXmlNodeModel::FirstChild() ) {
        if ($type == File) { # A file has no children.
            return Qt::XmlNodeModelIndex();
        }
        else {
            die "Type must be Directory" unless ($type == Directory);
            print STDERR 'It isn\'t really a directory!' unless $fi->isDir();
            my $dir = Qt::Dir($fi->absoluteFilePath());
            die "Directory doesn't exist." unless $dir->exists();

            my $children = $dir->entryInfoList([],
                                               m_filterAllowAll,
                                               m_sortFlags);
            if (defined $children && scalar @{$children} <= 0) {
                return Qt::XmlNodeModelIndex();
            }
            my $firstChild = Qt::FileInfo($children->[0]);
            return toNodeIndex($firstChild);
        }
    }
    elsif ( $axis == Qt::AbstractXmlNodeModel::PreviousSibling() ) {
        return nextSibling($nodeIndex, $fi, -1);
    }
    elsif ( $axis == Qt::AbstractXmlNodeModel::NextSibling() ) {
        return nextSibling($nodeIndex, $fi, 1);
    }

    print STDERR 'Don\'t ever get here!';
    return Qt::XmlNodeModelIndex();
}
# [4]

=begin

  No matter what part of the file system we model (the whole file
  tree or a subtree), \a node will always have \c{file:#/} as
  the document URI.

=cut

sub documentUri
{
    return Qt::Url('file:#/');
}

=begin

  This function returns Qt::XmlNodeModelIndex::Element if \a node
  is a directory or a file, and Qt::XmlNodeModelIndex::Attribute
  otherwise.

=cut

sub kind
{
    my ($node) = @_;
    if ( $node->additionalData() == Directory || $node->additionalData() == File ) {
        return Qt::XmlNodeModelIndex::Element();
    }
    else {
        return Qt::XmlNodeModelIndex::Attribute();
    }
}

=begin

  No order is defined for this example, so we always return
  Qt::XmlNodeModelIndex::Precedes, just to keep everyone happy.

=cut

sub compareOrder
{
    return Qt::XmlNodeModelIndex::Precedes();
}

=begin

  Returns the name of \a node. The caller guarantees that \a node is
  not null and that it is contained in this node model.

=cut

# [3]
sub name
{
    my ($node) = @_;
    return Qt::XmlName(m_names->{$node->additionalData()});
}
# [3]

=begin

  Always returns the Qt::XmlNodeModelIndex for the root of the
  file system, i.e. '/'.

=cut

sub root
{
    return toNodeIndex(Qt::FileInfo('/'));
}

=begin

  Returns the typed value for \a node, which must be either an
  attribute or an element. The Qt::Variant returned represents the atomic
  value of an attribute or the atomic value contained in an element.

  If the Qt::Variant is returned as a default constructed variant,
  it means that \a node has no typed value.

=cut

sub typedValue
{
    my ($node) = @_;
    my $fi = toFileInfo($node);

    if ( $node->additionalData() == Directory ) {
        # deliberate fall through.
    }
    elsif ( $node->additionalData() == File ) {
        Qt::Variant(Qt::String());
    }
    elsif ( $node->additionalData() == AttributeFileName ) {
        return Qt::Variant(Qt::String($fi->fileName()));
    }
    elsif ( $node->additionalData() == AttributeFilePath ) {
        return Qt::Variant(Qt::String($fi->filePath()));
    }
    elsif ( $node->additionalData() == AttributeSize ) {
        return Qt::Variant(Qt::String($fi->size()));
    }
    elsif ( $node->additionalData() == AttributeMIMEType ) {
        # We don't have any MIME detection code currently, so return
        # the most generic one. */
        return Qt::Variant(Qt::String('application/octet-stream'));
    }
    elsif ( $node->additionalData() == AttributeSuffix ) {
        return Qt::Variant(Qt::String($fi->suffix()));
    }

    print STDERR 'This line should never be reached.';
    return Qt::Variant(Qt::String());
}

=begin

  Returns the attributes of \a element. The caller guarantees
  that \a element is an element in this node model.

=cut

sub attributes
{
    my ($element) = @_;
    my @result;

    # Both elements has this attribute.
    my $forElement = toFileInfo($element);
    push @result, toNodeIndex($forElement, AttributeFilePath);
    push @result, toNodeIndex($forElement, AttributeFileName);

    if ($element->additionalData() == File) {
        push @result, toNodeIndex($forElement, AttributeSize);
        push @result, toNodeIndex($forElement, AttributeSuffix);
        #push @result, toNodeIndex(forElement, AttributeMIMEType));
    }
    else {
        die "Type must be a directory"
            unless $element->additionalData() == Directory;
    }

    return \@result;
}

1;
