package Polycom::App::URI;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(a softkeys);
our $VERSION = 0.01;

###################
# Exported Subroutines
###################
sub a
{
    my ($action, $content) = @_;
    return qq(<a href="$action">$content</a>);
}
sub softkeys
{
    my @items = @_;
    my @xml;

    my $nextIndex = 1;
    foreach my $item (@items)
    {
        my $action = $item->{action};

        # The "action" parameter is mandatory, but index will be generated if missing,
        # and leaving "label" blank will instruct the phone to auto-generate a label.
        if (defined $action)
        {
            my $label = $item->{label};
            if (!defined $label)
            {
                $label = '';
            }

            my $index = $item->{index};
            if (!defined $index)
            {
                $index = $nextIndex;
            }
            $nextIndex = $index + 1;

            push @xml, qq(<softkey index="$index" label="$label" action="$action"/>);
        }
    }

    return join '', @xml;
}


=head1 NAME

Polycom::App::URI - Module for working with internal URIs used for softkeys and hyperlinks in web applications for Polycom's SoundPoint IP and VVX series VoIP phones

=head1 SYNOPSIS

  use Polycom::App::URI qw(softkeys);
  use Polycom::App::Push;

  my $phone = Polycom::App::Push->new(address => "172.23.8.100", username => "Bob", password => "1234");

  # Send a message to a Polycom phone that provides custom soft keys using the softkeys() subroutine
  my $message =
	 '<html><h1>Fire drill at 2:00pm!</h1>'
	. softkeys(
		{label => 'Dir', action => 'Key:Directory'},
		{label => "Exit", action => 'SoftKey:Exit'})
	. '</html>';

  $phone->push_message({priority => 'critical', data => $message});

=head1 DESCRIPTION

The C<Polycom::App::URI> module is for writing web applications for Polycom's SoundPoint IP and VVX series VoIP phones. It provides facilities for generating XHTML pages for the microbrowser that include custom soft key definitions and hyperlinks that execute phone features such as dialing numbers or accessing the contact directory.

=head1 SUBROUTINES


=head2 a

  use Polycom::App::URI qw(a);

  # Prints '<a href="Key:Directory">View the phonebook</a>'
  print a('Key:Directory', 'View the phonebook');

This subroutine can be used when generating dynamic XHTML pages for the microbrowser on SoundPoint IP phones to generate a hyperlink with the specified URI and caption. The first argument is the internal URI, and the second argument is the caption.

=head2 softkeys

  use Polycom::App::URI qw(softkeys);

  # Prints '<softkey index="1" label="Dir" action="Key:Directory"/>
  #         <softkey index="2" label="Exit" action="SoftKey:Exit"/>'
  print softkeys(
        {index => 1, label => 'Dir', action => 'Key:Directory'},
        {index => 2, label => "Exit", action => 'SoftKey:Exit'});

This subroutine can be used when generating dynamic XHTML pages for the microbrowser on SoundPoint IP phones to place custom soft keys along the bottom of the screen. For VVX series IP phones, you should use the <button> HTML tag, instead.

The following parameters are supported:

  index     - the index (1 to 8), relative to the left side of the screen of the soft key.
  label     - the label (1 to 9 characters) to display on the soft key.
  action    - a URI to execute when the user presses the soft key. See the developer's guide for a list of supported URIs.

The C<action> parameter is the only mandatory parameter. If no C<label> parameter is specified, a default label will be displayed that corresponds to the action. Similarly, the C<index> parameter can be omitted if consecutive softkeys are desired. For instance, the following code snippet is roughly equivalent to the one above, and will produce two soft keys:

  print softkeys({action => 'Key:Directory'}, {action => 'SoftKey:Exit'});

=head1 SEE ALSO

I<Developer's Guide SoundPoint IP / SoundStation IP> - L<http://support.polycom.com/global/documents/support/setup_maintenance/products/voice/Web_Application_Developers_Guide_SIP_3_1.pdf>

C<Polycom::App::Push> - A module for sending push requests to Polycom VoIP phones.

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Zachary Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

'Together. Great things happen.';
