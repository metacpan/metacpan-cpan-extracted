package Template::Plugin::IO::All;

use strict;
use base qw( Template::Plugin );

use IO::All;
#use Data::Dumper;

$Template::Plugin::IO::All::VERSION = '0.01';

sub load {
    my ($class, $context) = @_;
    bless {
            _CONTEXT => $context,
        }, $class;
}

sub new {
    my ($self, $context, @params) = @_;
    if($context and not ref $context){
	$self->{_io} = io($context);
    }
    $self;
}


sub AUTOLOAD {
    my $sub = $Template::Plugin::IO::All::AUTOLOAD;
    $sub =~ s/^Template::Plugin::IO::All:://o;
#    print "[$sub]\n";

    if($sub =~ /^([+\-]?\d+)$/){    # Access content on a certain line
	shift->{_io}->[$1];
    }
    elsif($sub ne 'DESTROY'){
	shift->{_io}->$sub(@_);
    }
}

1;

__END__


=head1 NAME

Template::Plugin::IO::All - IO::All + Template

=head1 SYNOPSIS

  [% USE IO.All %]
  [% file = IO.All.new('some_file') %]

  [% file.all %]

  [% FOREACH line = file.getlines %]
    [% line %]
  [% END %]

  [% file.11 %]  # Return the 11st line 

  [% dir = IO.All.new('some_dir/') %]
  [% FOREACH entry = d.all %]
   [%- entry %]
  [% END %]

=head1 DESCRIPTION

Nothing much to explain. It's L<IO::All> plugin for Template. Fun and easy!

=head1 COPYRIGHT

Yung-chung Lin (a.k.a. xern) E<lt>xern@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=head1 SEE ALSO

L<IO::All>, L<Template::Plugin>

=cut

