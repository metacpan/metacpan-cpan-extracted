package Mozilla::Mechanize::Input;
use strict;
use warnings;

# $Id: Input.pm,v 1.4 2005/10/07 12:17:24 slanning Exp $

=head1 NAME

Mozilla::Mechanize::Input - A small class to interface with the Input objects

=head1 SYNOPSIS

sorry, read the source for now

=head1 DESCRIPTION

The C<Mozilla::Mechanize::Input> object is a thin wrapper around
HTML input elements.

=head1 METHODS

=head2 Mozilla::Mechanize::Input->new($input_node, $moz)

Initialize a new object. $input_node is a
L<Mozilla::DOM::HTMLElement|Mozilla::DOM::HTMLElement>
(or a node that can be QueryInterfaced to one); specifically,
it must be an HTMLInputElement, an HTMLButtonElement, an HTMLSelectElement,
or an HTMLTextAreaElement.
$moz is a L<Mozilla::Mechanize|Mozilla::Mechanize> object.
(This latter is a hack for `click', so that new pages can load
in the browser. The GUI has to be able to enter its main loop.
If you don't plan to use that method, you don't have to pass it in.)

=cut

sub new {
    my $class = shift;
    my $node = shift;
    my $moz = shift;

    my $iid;

    # turn the Node into the appropriate HTMLElement
    if (lc $node->GetNodeName eq 'input') {
        $iid = Mozilla::DOM::HTMLInputElement->GetIID;
    } elsif (lc $node->GetNodeName eq 'button') {
        $iid = Mozilla::DOM::HTMLButtonElement->GetIID;
    } elsif (lc $node->GetNodeName eq 'select') {
        $iid = Mozilla::DOM::HTMLSelectElement->GetIID;
    } elsif (lc $node->GetNodeName eq 'textarea') {
        $iid = Mozilla::DOM::HTMLTextAreaElement->GetIID;
    } else {
        my $errstr = "Invalid Input node";
        defined($moz) ? $moz->die($errstr) : die($errstr);
    }
    my $input = $node->QueryInterface($iid);

    my $self = { input => $input };
    $self->{moz} = $moz if defined $moz;
    bless($self, $class);
}

=head2 $input->name

Return the input-control name.

=cut

sub name {
    my $self = shift;
    my $input = $self->{input};
    return $input->GetAttribute('name');
}

=head2 $input->type

Return the type of the input control.
Note: for <select>, this returns 'select-one' for single select,
and 'select-multiple' for multiple. (I don't know why.)

=cut

sub type {
    my $self = shift;
    my $input = $self->{input};
    my $tagname = lc $input->GetNodeName;
    if ($tagname eq 'select') {
        if ($input->GetMultiple) {
            return 'select-multiple';
        } else {
            # I don't know what this is about,
            # but it works like Win32::IE::Mechanize
            return 'select-one';
        }
    } else {
        return $input->GetAttribute('type');
    }
}

=head2 $input->value( [$value] )

Get/Set the value of the input control.

=cut

sub value {
    my $self = shift;
    my $input = $self->{input};

    my $type = $self->type || '';
    $type =~ /^select/i and return $self->select_value( @_ );
    $type =~ /^radio/i  and return $self->radio_value( @_ );

    if (@_ && defined $_[0]) {
        my $value = shift;
        $input->SetValue($value);
    }
    return $input->GetValue;
}

=head2 $input->select_value( [$value] )

Mark all options with C<$value> as selected and unselect all other options.

=cut

sub select_value {
    my $self = shift;
    my $input = $self->{input};

    # XXX: I think this could be done better, but I just ported it straight

    my %vals;
    my @options = $input->GetOptions;

    if ( @_ ) {
        my @values = @_;
        if ( @values == 1 && ref $values[0] eq 'HASH' ) {
            my @ords = ref $values[0]->{n}
                ? @{ $values[0]->{n} } : $values[0]->{n};
            @values = ();
            foreach my $i ( @ords ) {
                ($i > 0) && ($i <= @options) and
                  push @values, $options[$i - 1]->GetValue;
            }
        }
        @values = @{ $values[0] } if @values == 1 && ref $values[0];

        # Make sure only the last value is set for:
        # select-one type with multiple values;
        # XXX: not sure if same type in Mozilla
        @values = ( $values[-1] ) if lc($self->type) eq 'select-one';

        %vals = map { ( $_ => undef ) } @values;

        for ( my $i = 0; $i < @options; $i++ ) {
            $options[$i]->SetSelected(exists $vals{ $options[$i]->GetValue });
        }
    } else {
        for ( my $i = 0; $i < @options; $i++ ) {
            $options[$i]->GetSelected and
              $vals{ $options[$i]->GetValue } = 1;
        }
    }

    return keys %vals;
}

=head2 $input->radio_value( [$value] )

Locate all radio-buttons with the same name within this form. Now
uncheck all values that are not equal to C<$value>.

=cut

sub radio_value {
    my $self = shift;
    my $input = $self->{input};

    return unless $self->type =~ /^radio/i;

    my $form = Mozilla::Mechanize::Form->new($input->GetForm, $self->{moz});
    my @radios = $form->_radio_group($self->name);

    if (@_) {
        my $value = shift;
        for (@radios) {
            $_->SetChecked(($_->GetValue eq $value) || 0);
        }
    }
    my ($value) = map($_->GetValue, grep($_->GetChecked, @radios));
    return $value;
}

=head2 $input->click

Calls the C<click()> method on the actual object.

=cut

sub click {
    my $self = shift;
    my $input = $self->{input};
    $input->Click();

    # XXX: if they didn't pass $moz to `new', they're stuck..
    my $moz = $self->{moz} || return;
    $moz->_wait_while_busy();
}


1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright 2005,2009 Scott Lanning <slanning@cpan.org>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
