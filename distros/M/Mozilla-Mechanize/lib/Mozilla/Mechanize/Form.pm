package Mozilla::Mechanize::Form;
use strict;
use warnings;

# $Id: Form.pm,v 1.4 2005/10/07 12:17:24 slanning Exp $

use Mozilla::Mechanize::Input;

=head1 NAME

Mozilla::Mechanize::Form - Mimic L<HTML::Form>

=head1 SYNOPSIS

Read the code for now

=head1 DESCRIPTION

The C<Mozilla::Mechanize::Form> object is a thin wrapper around
L<Mozilla::DOM::HTMLFormElement|Mozilla::DOM::HTMLFormElement>.

=head1 METHODS

=head2 Mozilla::Mechanize::Form->new($form_node, $moz);

Initialize a new object. $form_node is a
L<Mozilla::DOM::HTMLFormElement|Mozilla::DOM::HTMLFormElement>
(or a node that can be QueryInterfaced to one).
$moz is a L<Mozilla::Mechanize|Mozilla::Mechanize> object.
(This latter is a hack for `submit' and `reset',
so that new pages can load in the browser. The GUI has to be
able to enter its main loop. If you don't plan to use those
methods, you don't have to pass it in.)


=cut

sub new {
    my $class = shift;
    my $node = shift;
    my $moz = shift;

    # turn the Node into an HTMLFormElement
    my $form = $node->QueryInterface(Mozilla::DOM::HTMLFormElement->GetIID);

    my $self = { form => $form };
    $self->{moz} = $moz if defined $moz;
    bless($self, $class);
}

=head2 $form->method( [$new_method] )

Get/Set the I<method> used to submit the from (i.e. B<GET> or B<POST>).

=cut

sub method {
    my $self = shift;
    my $val = shift;
    my $form = $self->{form};
    $form->SetMethod($val) if defined $val;
    my $method = $form->GetMethod;

    # XXX: provide default value (not sure about this...)
    $method = 'GET' unless $method =~ /\S/;
    return $method;
}

=head2 $form->action( [$new_action] )

Get/Set the I<action> for submitting the form.

=cut

sub action {
    my $self = shift;
    my $val = shift;
    my $form = $self->{form};
    $form->SetAction($val) if defined $val;
    # This is supposed to be required in HTML 4.01
    return $form->GetAction;
}

=head2 $form->enctype( [$new_enctype] )

Get/Set the I<enctype> of the form.

=cut

sub enctype {
    my $self = shift;
    my $val = shift;
    my $form = $self->{form};
    $form->SetEnctype($val) if defined $val;
    my $enctype = $form->GetEnctype;

    # XXX: provide default value (not sure about this...)
    $enctype = 'application/x-www-form-urlencoded' unless $enctype =~ /\S/;
    return $enctype;
}

=head2 $form->name()

Return the name of this form.

=cut

sub name {
    my $self = shift;
    my $val = shift;
    my $form = $self->{form};
    $form->SetName($val) if defined $val;
    return $form->GetName;
}

=head2 $form->attr( $name[, $new_value] )

Get/Set any of the attributes from the FORM-tag
(acceptcharset, action, enctype, method, name, target
(returns undef if $name isn't one of these)).

=cut

sub attr {
    my $self = shift;
    return unless @_;
    my $name = shift;
    my $form = $self->{form};

    my ($attr) = grep $name =~ /^$_$/i, qw(AcceptCharset Action Enctype Method Name Target);
    return unless defined $attr;

    my $method = "Set$attr";
    $form->$method(shift) if @_;
    $method = "Get$attr";
    my $val = $form->$method;

    # Defaults for non-present attributes
    unless ($val =~ /\S/) {
        $val = 'GET' if $attr eq 'Method';
        $val = 'application/x-www-form-urlencoded' if $attr eq 'Enctype';
        # action is supposed to be required in HTML 4.01
    }

    return $val;
}

=head2 $form->inputs()

Returns a list of L<Mozilla::Mechanize::Input> objects.
In scalar context it will return the number of inputs.

B<XXX: I'm confused about how radio buttons are implemented.
Win32::IE::Mechanize only pushes on the first one for some reason.
(I push them all for now.)>

=cut

{
    # Recursively get input elements. This is necessary in order
    # to preserve their order. (cf. _extract_links, _extract_images in Mechanize.pm)
    my (@inputs, %radio_seen);

    sub inputs {
        my ($self, $subelement) = @_;   # 2nd arg is undocumented
        my $node;

        # The first time, it's called with no subelement
        if (defined $subelement) {
            $node = $subelement;
        } else {
            @inputs = ();
            %radio_seen = ();
            $node = $self->{form};
        }

        # If it's an input element, get it; otherwise, recurse if has children
        if ($node->GetNodeName =~ /^(input|button|select|textarea)$/i) {
            my $tagname = lc $1;
            if ($tagname eq 'input') {
                my $input = $node->QueryInterface(Mozilla::DOM::HTMLInputElement->GetIID);
                my $name = lc $input->GetName;
                my $type = lc $input->GetType;
                # For some reason, we only get the first in a radio group
                unless ($type eq 'radio' and $radio_seen{$name}++) {
                    push @inputs, Mozilla::Mechanize::Input->new($node, $self->{moz});
                }
            } else {
                push @inputs, Mozilla::Mechanize::Input->new($node, $self->{moz});
            }
            $self->debug("added '$tagname' input");
        } elsif ($node->HasChildNodes) {
            my @children = $node->GetChildNodes;
            # skips #text nodes
            foreach my $child (grep {$_->GetNodeName !~ /^#/} @children) {
                $self->inputs($child);
            }
        }

        # Continue only at the top-level
        return if defined $subelement;

        return wantarray ? @inputs : scalar @inputs;
    }
}

=head2 $form->find_input( $name[, $type[, $index]] )

This method is used to locate specific inputs within the form.  All
inputs that match the arguments given are returned.  In scalar context
only the first is returned, or C<undef> if none match.

If $name is specified, then the input must have the indicated name.

If $type is specified, then the input must have the specified type.
The following type names are used: "text", "password", "hidden",
"textarea", "file", "image", "submit", "radio", "checkbox", and "option".
(and "button" and "select"?)

The $index is the sequence number of the input matched where 1 is the
first.  If combined with $name and/or $type then it select the I<n>th
input with the given name and/or type.

(This method is ported from L<HTML::Form>)

=cut

sub find_input {
    my $self = shift;
    my( $name, $type, $index ) = @_;

    my $form = $self->{form};

    my $typere = qr/.*/;
    $type and $typere = $type =~ /^select/i ? qr/^$type/i : qr/^$type$/i;

    if ( wantarray ) {
        my( $cnt, @res ) = ( 0 );
        for my $input ( $self->inputs ) {
            if ( defined $name ) {
                $input->name or next;
                $input->name ne $name and next;
            }

            $input->type =~ $typere or next;
            $cnt++;
            $index && $index ne $cnt and next;
            push @res, $input;
        }
        return @res;
    } else {
        $index ||= 1;
        for my $input ( $self->inputs ) {
            if ( defined $name ) {
                $input->name or next;
                $input->name ne $name and next;
            }
            $input->type =~ $typere or next;
            --$index and next;
            return $input;
        }
        return undef;
    }
}

=head2 $form->value( $name[, $new_value] )

Get/Set the value for the input-control with specified name.

=cut

sub value {
    my $self = shift;
    my $input = $self->find_input( shift );
    return $input->value( @_ );
}

=head2 $form->submit()

Submit this form. (Note: does B<not> trigger onSubmit.)

=cut

sub submit {
    my $self = shift;
    my $form = $self->{form};
    $form->Submit();

    # XXX: if they didn't pass $moz to `new', they're stuck..
    my $moz = $self->{moz} || return;
    $moz->_wait_while_busy();
}

=head2 $form->reset()

Reset inputs to their default values.
(Note: I added this method, though it wasn't in WWW::Mechanize.)

=cut

sub reset {
    my $self = shift;
    my $form = $self->{form};
    $form->Reset();

    # XXX: if they didn't pass $moz to `new', they're stuck..
    my $moz = $self->{moz} || return;
    $moz->_wait_while_busy();
}

=head2 $self->_radio_group( $name )

Returns a list of Mozilla::DOM::HTMLInputElement objects with name eq $name.
(Intended for use with Input.pm's radio_value method.)

=cut

sub _radio_group {
    my $self = shift;
    my $form = $self->{form};

    my $name = shift or return;
    my @rgroup;

    my @inputs = $form->GetElementsByTagName('input');
    my $iid = Mozilla::DOM::HTMLInputElement->GetIID;
    foreach my $input (map {$_->QueryInterface($iid)} @inputs) {
        next unless lc($input->GetType) eq 'radio';
        next unless lc($input->GetName) eq lc($name);
        push @rgroup, $input;
    }

    return wantarray ? @rgroup : \@rgroup;
}

sub debug {
    my ($self, $msg) = @_;
    my (undef, $file, $line) = caller();
    print STDERR "$msg at $file line $line\n" if $self->{debug};
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
