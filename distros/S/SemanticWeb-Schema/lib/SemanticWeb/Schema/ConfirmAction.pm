package SemanticWeb::Schema::ConfirmAction;

# ABSTRACT: <p>The act of notifying someone that a future event/action is going to happen as expected

use Moo;

extends qw/ SemanticWeb::Schema::InformAction /;


use MooX::JSON_LD 'ConfirmAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ConfirmAction - <p>The act of notifying someone that a future event/action is going to happen as expected

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>The act of notifying someone that a future event/action is going to
happen as expected.</p> <p>Related actions:</p> <ul> <li><a
class="localLink" href="http://schema.org/CancelAction">CancelAction</a>:
The antonym of ConfirmAction.</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::InformAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
