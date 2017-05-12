package Solstice::SystemMessageFactory;

# $Id: generated_model.tmpl 110 2005-09-02 16:28:22Z mcrawfor $

=head1 NAME

Solstice::SystemMessageFactory - Creates groups of SystemMessages

=head1 SYNOPSIS

  use Solstice::SystemMessageFactory;

  my $model = Solstice::SystemMessageFactory->new();
  
=head1 DESCRIPTION

Welp, it busts em out
=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

use Solstice::Database;
use Solstice::Configure;
use Solstice::SystemMessage;

our ($VERSION) = ('$Revision: 110 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

None by default.

=head2 Methods

=over 4

=item new()

Constructor.

=cut

sub new {
    my $obj = shift;
    
    my $self = $obj->SUPER::new(@_);
    
    return $self;
}


sub getAllMessagesHash {
    my $self = shift;
    
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();
    return $self->_returnFromSQL('SELECT system_message_id, show_on_all_tools, start_date, end_date, message FROM '.$db_name.'.SystemMessage');
}


sub getCurrentMessageHash {
    my $self = shift;

    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();
    return $self->_returnFromSQL('SELECT system_message_id, show_on_all_tools, start_date, end_date, message
    FROM '.$db_name.'.SystemMessage 
    WHERE start_date < NOW() AND end_date > NOW()');
}


sub getAllAppMessageHash {
    my $self = shift;

    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();
    return $self->_returnFromSQL('SELECT system_message_id, show_on_all_tools, start_date, end_date, message 
    FROM '.$db_name.'.SystemMessage
    WHERE show_on_all_apps = 1 AND start_date < NOW() AND end_date > NOW()');
}



sub _returnFromSQL {
    my $self = shift;
    my $sql  = shift;

    my $db = Solstice::Database->new();
    $db->readQuery($sql);

    my %return_hash;
    while (my $data = $db->fetchRow()) {
        my $sys_mess = Solstice::SystemMessage->new();
        $sys_mess->_setID($data->{'system_message_id'});
        $sys_mess->setShowOnAllTools($data->{'show_on_all_tools'});
        $sys_mess->setStartDate(Solstice::DateTime->new($data->{'start_date'}));
        $sys_mess->setEndDate(Solstice::DateTime->new($data->{'end_date'}));
        $sys_mess->setMessage($data->{'message'});

        $return_hash{$data->{'system_message_id'}} = $sys_mess;
    }

    return \%return_hash;
}

1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 110 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
