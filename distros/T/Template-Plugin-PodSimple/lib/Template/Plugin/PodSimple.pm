=head1 NAME

Template::Plugin::PodSimple - simple Pod::Simple plugin for TT

=head1 SYNOPSIS

    [% USE PodSimple %]
    [% PodSimple.parse('format',string_containing_pod_or_filename) %]

=head1 DESCRIPTION

    [%    SET somepod = "
    
    =head1 NAME
    
    the name
    
    =head1 DESCRIPTION
    
    somepod
    
    =cut
    
    ";
    USE PodSimple;
    %]
    
    [% PodSimple.parse('Text', somepod, 76) %]
    [% PodSimple.parse('xml', somepod) %]
    [% mySimpleTree = PodSimple.parse('tree', somepod ) %]
    [% PodSimple.parse('html', somepod, 'pod_link_prefix','man_link_prefix') %]

Text translates to L<Pod::Simple::Text|Pod::Simple::Text>.
When dealing with text, the 3rd argument is the value for C< $Text::Wrap::columns >.

xMl translates to L<Pod::Simple::XMLOutStream|Pod::Simple::XMLOutStream>.

tree translates to L<Pod::Simple::SimpleTree|Pod::Simple::SimpleTree>,
and the tree B<root> is what's returned.
This is what you want to use if you want to create your own formatter.

htMl translates to L<Pod::Simple::HTML|Pod::Simple::HTML>.
When dealing with htMl, the 3rd and 4th arguments are
is used to prefix all non-local LE<lt>E<gt>inks,
by temporarily overriding
C<< *Pod::Simple::HTML::do_pod_link >>.
and
C<< *Pod::Simple::HTML::do_man_link >>.
pod_link_prefix is "?" by default.
man_link_prefix is C<< http://man.linuxquestions.org/index.php?type=2&query= >>
by default.
The prefix always gets html escaped by Pod::Simple.
An example man link is C<< L<crontab(5)> >>.



=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>,
L<Pod::Simple|Pod::Simple>.

=head1 BUGS

To report bugs, go to
E<lt>http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-PodSimpleE<gt>
or send mail to E<lt>bug-Template-Plugin-PodSimple#rt.cpan.orgE<gt>.

=head1 LICENSE

Copyright (c) 2003 by D.H. (PodMaster). All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. The LICENSE file contains the full
text of the license.

=cut

package Template::Plugin::PodSimple;
use strict;
use Pod::Simple;
use Carp 'croak';
use base qw[ Template::Plugin ];
use vars '$VERSION';
$VERSION = sprintf "%d.%03d", q$Revision: 1.10 $ =~ /(\d+).(\d+)/g;


my %map = (
    tree => 'SimpleTree',
    html => 'HTML',
    text => 'Text',        
    xml  => 'XMLOutStream',
);

my $pod_link_prefix = '';
my $man_link_prefix = '';
sub _do_man_link {
    my($self, $link) = @_;
    my $to = $link->attr('to');
    $to =~ s/\(\d+\)$//;
    return $man_link_prefix.$self->unicode_escape_url($to);
}
sub _do_pod_link {
  my($self, $link) = @_;
  my $to = $link->attr('to');
  my $section = $link->attr('section');
  return undef unless(  # should never happen
    (defined $to and length $to) or
    (defined $section and length $section)
  );

#  if(defined $to and length $to) {
#    $to = $self->resolve_pod_page_link($to, $section);
#    return undef unless defined $to and length $to;
     # resolve_pod_page_link returning undef is how it
     #  can signal that it gives up on making a link
     # (I pass it the section value, but I don't see a
     #  particular reason it'd use it.)
#  }
  
  if(defined $section and length($section .= '')) {
    $section =~ tr/ /_/;
    $section =~ tr/\x00-\x1F\x80-\x9F//d if 'A' eq chr(65);
    $section = $self->unicode_escape_url($section);
     # Turn char 1234 into "(1234)"
    $section = '_' unless length $section;
  }
  
  foreach my $it ($to, $section) {
    $it =~ s/([^\._abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789])/sprintf('%%%02X',ord($1))/eg
     if defined $it;
      # Yes, stipulate the list without a range, so that this can work right on
      #  all charsets that this module happens to run under.
      # Altho, hmm, what about that ord?  Presumably that won't work right
      #  under non-ASCII charsets.  Something should be done about that.
  }
  
  my $out = $to if defined $to and length $to;
  $out .= "#" . $section if defined $section and length $section;
  return undef unless length $out;
  return $pod_link_prefix.$out;  
}

sub parse {
    my $self = shift;
    my $class = lc shift;
    $pod_link_prefix = $_[1] || '?';
    $man_link_prefix = $_[2] || 'http://man.linuxquestions.org/index.php?type=2&query=';

    my $somestring="";
    my $new;

    unless( exists $INC{"lib/Pod/Simple/$map{$class}.pm"} ){
        eval "require Pod::Simple::$map{$class};";
        croak("Template::Plugin::PodSimple could not load Pod::Simple::$map{$class} : $@ $!")
            if $@;
    }
            
    $new = "Pod::Simple::$map{$class}"->new();

    croak("`$class' not recognized by Template::Plugin::PodSimple $@ $!")
        unless defined $new;

    $new->output_string( \$somestring );

    local *Pod::Simple::HTML::do_pod_link = \&_do_pod_link
        and
        local *Pod::Simple::HTML::do_man_link = \&_do_man_link
            if $class eq 'html';

    local $Text::Wrap::columns = $_[1] if $class eq 'text';

    if( $_[0] =~ /\n/ ){
        $new->parse_string_document( $_[0] );
    } else {
        $new->parse_file($_[0]);
    }

    $somestring = $new->root if $class eq 'tree';

    return $somestring;
}


1;
__END__
sub filter {
  my($class, $source) = @_;
  my $new = $class->new;
  my $somestring="";
  $new->output_string( \$somestring );
  
  if(ref($source || '') eq 'SCALAR') {
    $new->parse_string_document( $$source );
  } elsif(ref($source)) {  # it's a file handle
    $new->parse_file($source);
  } else {  # it's a filename
    $new->parse_file($source);
  }
  
  return $somestring;
}
