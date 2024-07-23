package Net::Async::Slack::Event::WorkflowStepEdit;

use strict;
use warnings;

our $VERSION = '0.015'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::WorkflowStepEdit - app added as a workflow step

=head1 DESCRIPTION

Example input data:

    {
        action_ts => "1679230481.238183",
        callback_id => "some_workflow",
        enterprise => undef,
        is_enterprise_install => false,
        team => {
            domain => "example",
            id => "T03823123"
        },
        token => "Io2ca8sd8f1n4n12uu123Sf1",
        trigger_id => "5023918231231.12318832904.823812sc8a8ed8af8a0c908ca8ed8aff",
        type => "workflow_step_edit",
        user => {
            id => "U2Q84EA9E",
            team_id => "T03832314",
            username => "test"
        },
        workflow_step => {
            inputs => {},
            outputs => [],
            step_id => "55bcc092-5fa8-4515-b75a-58008afdbed7",
            workflow_id => "472313182471232832"
        }
    }

=cut

sub type { 'workflow_step_edit' }
sub callback_id { shift->{callback_id} }
sub trigger_id { shift->{trigger_id} }
sub action_ts { shift->{action_ts} }
sub token { shift->{token} }
sub workflow_step { shift->{workflow_step} }
sub workflow_step_edit_id { shift->{workflow_step}{workflow_step_edit_id} }
sub step_id { shift->{workflow_step}{step_id} }
sub workflow_id { shift->{workflow_step}{workflow_id} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2024. Licensed under the same terms as Perl itself.
