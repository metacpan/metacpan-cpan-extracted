package Sque::Encoder;
$Sque::Encoder::VERSION = '0.010';
use Any::Moose 'Role';
use JSON;

# ABSTRACT: Any::Moose role for encoding Sque structures
#
# =attr encoder
#
# JSON encoder by default.
#
# =cut
has encoder => ( is => 'ro', default => sub { JSON->new->utf8 } );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sque::Encoder - Any::Moose role for encoding Sque structures

=head1 VERSION

version 0.010

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
