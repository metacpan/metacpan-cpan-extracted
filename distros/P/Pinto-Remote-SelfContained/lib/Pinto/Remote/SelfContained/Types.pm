package
    Pinto::Remote::SelfContained::Types; # hide from PAUSE

use strict;
use warnings;

use Type::Utils qw(:all);
use Types::Standard qw(ArrayRef Dict InstanceOf Optional Str);

our $VERSION = '1.000';

use Type::Library -base, -declare => qw(
    BodyPart
    Chrome
    SingleBodyPart
    Uri
    Username
);

my $BaseBodyPart = declare as Dict[
    name => Str,
    data => Optional[Str],
    filename => Optional[Str | InstanceOf['Path::Tiny']],
    type => Optional[Str],
    encoding => Optional[Str],
];

declare BodyPart,
    as $BaseBodyPart,
    where { defined($_->{data}) != defined($_->{filename}) },
    message { $BaseBodyPart->validate($_) or "A body part needs either data OR a filename" };

class_type Chrome, { class => 'Pinto::Remote::SelfContained::Chrome' };

declare SingleBodyPart,
    as ArrayRef[BodyPart],
    where { @$_ == 1 },
    message { (ArrayRef[BodyPart])->validate($_) or "Exactly one archive to add is needed" };

class_type Uri, { class => 'URI' };
coerce Uri, from Str, via { require URI; URI->new($_) };

declare Username, as Str, where { /^[^:]+\z/ };

1;
__END__

=head1 NAME

Pinto::Remote::SelfContained::Types - types for Pinto::Remote::SelfContained

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
