package SemanticWeb::Schema::RegisterAction;

# ABSTRACT: <p>The act of registering to be a user of a service

use Moo;

extends qw/ SemanticWeb::Schema::InteractAction /;


use MooX::JSON_LD 'RegisterAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::RegisterAction - <p>The act of registering to be a user of a service

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>The act of registering to be a user of a service, product or web
page.</p> <p>Related actions:</p> <ul> <li><a class="localLink"
href="http://schema.org/JoinAction">JoinAction</a>: Unlike JoinAction,
RegisterAction implies you are registering to be a user of a service,
<em>not</em> a group/team of people.</li> <li>[FollowAction]]: Unlike
FollowAction, RegisterAction doesn't imply that the agent is expecting to
poll for updates from the object.</li> <li><a class="localLink"
href="http://schema.org/SubscribeAction">SubscribeAction</a>: Unlike
SubscribeAction, RegisterAction doesn't imply that the agent is expecting
updates from the object.</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::InteractAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
