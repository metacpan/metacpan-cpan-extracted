package Siebel::Srvrmgr::Nagios::Server::Component;
use XML::Rabbit;

=pod

=head1 NAME

Siebel::Srvrmgr::Nagios::Server::Component - Perl extension to represents a Siebel component instance of the Nagios plugin XML configuration file

=head1 DESCRIPTION

Represents a Siebel component instance of the Nagios plugin XML configuration file.

This class applies the Moose role L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Component>.

=head1 ATTRIBUTES

=head2 name

The name of the component.

=cut

has_xpath_value 'alias' => './@alias', reader => 'get_alias';

=head2 description

The description of the Siebel component.

=cut

has_xpath_value 'description' => './@description', reader => 'get_description';

=head2 componentGroup

The component group name of which the component is part of.

=cut

has_xpath_value 'componentGroup' => './@ComponentGroup', reader => 'get_componentGroup';

=head2 OKStatus

A string representing the status that indicates that the component is working as expected.

=cut

has_xpath_value 'OKStatus' => './@OKStatus', reader => 'get_OKStatus';

=head2 TaskOKStatus

A string representing the tasks status of the component is the one expected.

=cut

has_xpath_value 'taskOKStatus' => './@taskOKStatus', reader => 'get_taskOKStatus';

=head2 criticality

An integer indicating how critical is for the Siebel Server if this component does not have the expected status.

Higher values means more critical the component is.

=cut

has_xpath_value 'criticality' => './@criticality', reader => 'get_criticality';

with 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Component';

# this method exists to enable setting a OKStatus if the component is using the respective component group default
sub _set_ok_status {

    my $self  = shift;
    my $value = shift;

    my $meta = __PACKAGE__->meta();
    my $attr = $meta->get_attribute('OKStatus');
    $attr->set_value( $self, $value );

}

sub _set_task_status {

    my $self  = shift;
    my $value = shift;

    my $meta = __PACKAGE__->meta();
    my $attr = $meta->get_attribute('taskOKStatus');
    $attr->set_value( $self, $value );

}

finalize_class();
__END__
=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut
