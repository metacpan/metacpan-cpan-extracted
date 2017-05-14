package TreeModelCompleter;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Completer );
    #Q_PROPERTY(Qt::String separator READ separator WRITE setSeparator)
use QtCore4::slots
    setSeparator => ['const QString &'];

sub sep() {
    return this->{sep};
}

# [0]
# [1]
sub NEW
{
    my ($class, $model, $parent) = @_;
    if ( !$model->isa('Qt::AbstractItemModel') ) {
        $parent = $model;
        $model = undef;
    }
    $class->SUPER::NEW($model, $parent);
}
# [1]
# [0]

sub setSeparator
{
    my ($separator) = @_;
    this->{sep} = $separator;
}

# [2]
sub separator
{
    return sep;
}
# [2]

sub escapeRegex {
    my ($pattern) = @_;
    $pattern =~ s/([.])/\\$1/g;
    return $pattern;
}

# [3]
sub splitPath
{
    my ($path) = @_;
    if (!defined sep) {
        return this->SUPER::splitPath($path);
    }

    # Perl's split always uses a regex, and skips empty parts.  So we've got to
    # escape it.
    my @fields = split escapeRegex(sep()), $path;
    if ( substr( $path, -(length sep()) ) eq sep() ) {
        push @fields, '';
    }
    return \@fields;
}
# [3]

# [4]
sub pathFromIndex
{
    my ($index) = @_;
    if (!defined sep) {
        return this->SUPER::pathFromIndex($index);
    }

    # navigate up and accumulate data
    my @dataList;
    for (my $i = $index; $i->isValid(); $i = $i->parent()) {
        unshift @dataList, model()->data($i, completionRole())->toString();
    }

    return join sep(), @dataList;
}
# [4]

1;
