package Tangerine::HookData;
$Tangerine::HookData::VERSION = '0.23';
use strict;
use warnings;
use Tangerine::Utils qw/accessor/;

sub new {
    my $class = shift;
    my %args = @_;
    bless {
        _children => $args{children} // [],
        _hooks => $args{hooks} // [],
        _modules => $args{modules} // {},
        _type => $args{type},
    }, $class
}

sub children { accessor _children => @_  }
sub hooks { accessor _hooks => @_  }
sub modules { accessor _modules => @_  }
sub type { accessor _type => @_ }

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tangerine::HookData - An envelope for data returned from a hook

=head1 SYNOPSIS

    my $data = Tangerine::HookData->new(
        modules => {
            'ExtUtils::MakeMaker' => [
                Tangerine::Occurence->new(
                    line => 3,
                    version => '6.30',
                ),
            ],
        },
        hooks => [
            Tangerine::Hook->new(
                type => 'compile',
                run => \&Tangerine::hook::myhook::run,
            ),
        ],
        children => [ qw/myhook_statement with_args ;/ ]
    );

=head1 DESCRIPTION

Hooks use this class to encapsulate their results before returning them
to the main Tangerine object.

A hook may return a hash reference of module names pointing to lists of
L<Tangerine::Occurence> objects, a list reference of L<Tangerine::Hook>
objects that should be added to the list of hooks to run and a statement
which should be parsed in the context of the current line.

=head1 METHODS

=over

=item C<children>

Returns or sets the statement to be analysed.  This is a simple list
reference of significant children.  Tangerine statements are created
from L<PPI::Statement>'s C<schildren> method.

=item C<hooks>

Returns or sets a list reference of L<Tangerine::Hook> hooks to be run.

=item C<modules>

Returns or sets a hash reference of module names pointing to list
references of L<Tangerine::Occurence> objects.

=item C<type>

Forces the data type, overriding the hook's type value.  The possible
values being C<package>, C<compile>, or C<runtime>.

=back

=head1 SEE ALSO

L<Tangerine>, L<Tangerine::Hook>, L<Tangerine::Occurence>, L<PPI::Statement>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016 Petr Šabata

See LICENSE for licensing details.

=cut
