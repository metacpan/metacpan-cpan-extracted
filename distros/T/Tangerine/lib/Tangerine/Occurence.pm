package Tangerine::Occurence;
$Tangerine::Occurence::VERSION = '0.23';
use strict;
use warnings;
use Tangerine::Utils qw/accessor/;

sub new {
    my $class = shift;
    my %args = @_;
    bless {
        _version => $args{version},
        _line => $args{line} // 0,
        _extra => $args{extra} // {},
    }, $class
}

sub version { accessor _version => @_ }
sub line { accessor _line => @_  }
sub extra { accessor _extra => @_  }

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tangerine::Occurence - A simple object describing a package, compile or
runtime statement occurence in the examined document

=head1 DESCRIPTION

Instances of this object are returned by C<package>, C<compile> and
Cruntime> L<Tangerine> methods.

=head1 METHODS

=over

=item C<line>

Returns the line number of this particular occurence.

=item C<version>

Returns the required version of a used module, if applicable.

=item C<extra>

Returns a hash reference with additional extra flags.  This is currently
unused.

=back

=head1 SEE ALSO

L<Tangerine>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016 Petr Šabata

See LICENSE for licensing details.

=cut
