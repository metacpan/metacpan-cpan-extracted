package SemanticWeb::Schema::ScheduleAction;

# ABSTRACT: <p>Scheduling future actions

use Moo;

extends qw/ SemanticWeb::Schema::PlanAction /;


use MooX::JSON_LD 'ScheduleAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ScheduleAction - <p>Scheduling future actions

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>Scheduling future actions, events, or tasks.</p> <p>Related actions:</p>
<ul> <li><a class="localLink"
href="http://schema.org/ReserveAction">ReserveAction</a>: Unlike
ReserveAction, ScheduleAction allocates future actions (e.g. an event, a
task, etc) towards a time slot / spatial allocation.</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::PlanAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
