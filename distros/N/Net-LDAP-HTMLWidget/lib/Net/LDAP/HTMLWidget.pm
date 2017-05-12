package Net::LDAP::HTMLWidget;
use strict;
use warnings;

our $VERSION = '0.07';
# pod after __END__
use Carp qw(croak);
our $DECODE = 0;

sub fill_widget {
    my ($self,$entry,$widget)=@_;
    if (ref($entry) and $entry->isa('HTML::Widget')) {
        $widget = $entry;
        $entry = $self;
    }
    my @elements = $widget->find_elements;
    foreach my $element ( @elements ) {
        my $name=$element->name;
        next unless $name && $entry->exists($name) && $element->can('value');
        my $v = $entry->get_value($name);
        if ($DECODE) {
            $v = Encode::decode($DECODE, $v);
        }
	    $element->value( $v );
    }
}


sub populate_from_widget {
    my ($self,$entry,$result,$ldap)=@_;
    if (ref($entry) and $entry->isa('HTML::Widget::Result')) {
        $ldap = $result;
        $result = $entry;
        $entry = $self;
    }

    $ldap = $self if (ref $self && ($self->isa('Net::LDAP') || $self->isa('Catalyst::Model::LDAP::Connection')));
    $ldap = $self->_ldap_client if (ref($self) and $self->isa('Catalyst::Model::LDAP::Entry') && $self->_ldap_client);
    
    croak("No LDAP connection: " . ref($self)) unless $ldap;
    
    foreach my $oc ( ref $entry->get_value('objectClass') 
        ? @{$entry->get_value('objectClass')} 
        : ($entry->get_value('objectClass'))) {
	        foreach my $attr ($ldap->schema->must($oc),$ldap->schema->may($oc)) {
	            $entry->replace($attr->{name}, $result->param($attr->{name})) 
		            if defined $result->param($attr->{name});
	        }
    }
    return $entry->update($ldap);
}


1;

__END__

=pod

=head1 NAME

Net::LDAP::HTMLWidget - Like FromForm but with Net::LDAP and HTML::Widget

=head1 SYNOPSIS

You'll need a working Net::LDAP setup and some knowledge of HTML::Widget
and Catalyst. If you have no idea what I'm talking about, check the (sparse)
docs of those modules.

   
   package My::Controller::Pet;    # Catalyst-style
   
   # define the widget in a sub (DRY)
   sub widget_pet {
     my ($self,$c)=@_;
     my $w=$c->widget('pet')->method('get');
     $w->element('Textfield','name')->label('Name');
     $w->element('Textfield','age')->label('Age');
     ...
     return $w;
   }
     
   # this renders an edit form with values filled in from the DB 
   sub edit : Local {
     my ($self,$c,$id)=@_;
  
     # get the object
     my $item=$c->model('LDAP')->search(uid=>$id);
     $c->stash->{item}=$item;
  
     # get the widget
     my $w=$self->widget_pet($c);
     $w->action($c->uri_for('do_edit/'.$id));
    
     # fill widget with data from DB
     Net::LDAP::HTMLWidget->fill_widget($item,$w);
  }
  
  sub do_edit : Local {
    my ($self,$c,$id)=@_;
    
    # get the object from DB
    my $item=$c->model('LDAP')->search(uid=>$id);
    $c->stash->{item}=$item;
    
    $ get the widget
    my $w=$self->widget_pet($c);
    $w->action($c->uri_for('do_edit/'.$id));
    
    # process the form parameters
    my $result = $w->process($c->req);
    $c->stash->{'result'}=$result;
    
    # if there are no errors save the form values to the object
    unless ($result->has_errors) {
        Net::LDAP::HTMLWidget->populate_from_widget($item,$result);
        $c->res->redirect('/users/pet/'.$id);
    }
  }

  
=head1 DESCRIPTION

Something like Class::DBI::FromForm / Class::DBI::FromCGI but using
HTML::Widget for form creation and validation and Net::LDAP.

=head2 Methods

=head3 fill_widget $item, $widget

Fill the values of a widgets elements with the values of the LDAP object.

=head3 populate_from_widget $item, $results, $ldap_connection

Updates the $item with new values from $result and updated using 
$ldap_connection.


=head1 CHARACTER ENCODING

As a result of utf-8 handling in general beeing a pain in the ass,
we also provide an bad hack to work around certain odities. 

We have a package scoped variabel called DECODE which, if set, will
cause values from the ldap-server to be decoded from that encoding
to perls internal string format before it gets added to the HTML::Widget

=head2 Example
    
    package MyApp::LDAP::Entry;
    use base qw/Net::LDAP::HTMLWidget/;
    
    $Net::LDAP::HTMLWidget::DECODE = 'utf-8';
    
    1;

=head1 AUTHOR

Thomas Klausner, <domm@cpan.org>, http://domm.zsi.at
Marcus Ramberg, <mramberg@cpan.org>
Andreas Marienborg, <andremar@cpan.org>

=head1 LICENSE

This code is Copyright (c) 2003-2006 Thomas Klausner.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut




