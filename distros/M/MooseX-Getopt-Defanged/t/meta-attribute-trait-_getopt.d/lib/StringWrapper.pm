package StringWrapper;

use 5.010;
use utf8;

use strict;
use warnings;


use version; our $VERSION = qv('v1.18.0');


use overload q<""> => \&as_string;


sub new {
    my ($class, $string) = @_;

    return bless \$string, $class;
} # end new()


sub as_string {
    my ($self) = @_;

    return ${$self};
} # end as_string()


1;

__END__

=encoding utf8

=for stopwords StringWrapper

=head1 NAME

StringWrapper - Dumb object for testing Moose object coercion.


=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :
