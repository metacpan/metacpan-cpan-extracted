package Template::Like;

use strict;
use File::Spec;
use IO::File;

use Template::Like::Processor;

$Template::Like::VERSION = '0.12';

#=====================================================================
# new
#---------------------------------------------------------------------
# - API
# $instance = Template::Like->new( %option )
#---------------------------------------------------------------------
# - args
# %option ... see also pod. ( HASHREF )
#---------------------------------------------------------------------
# - Example
# my $t = Template::Like->new( TAG_STYLE => 'asp' );
#=====================================================================
sub new {
  my $class = shift;

  my $self  = bless {
    OPTION => ref $_[0] ? $_[0] : { @_ },
  }, $class;

  return $self;
}



#=====================================================================
# process
#---------------------------------------------------------------------
# - API
# $rc = $t->process( $input, $params, $output, $option );
#---------------------------------------------------------------------
# - args
# $input  ... INPUT  ( SCALAR, SCALARREF, ARRAYREF, HASHREF, GLOB )
# $params ... PARAMS ( HASHREF )
# $output ... OUTPUT ( SCALAR, SCALARREF, ARRAYREF, HASHREF, GLOB, Apache::Request )
# $option ... see also pod. ( HASHREF )
#---------------------------------------------------------------------
# - Example
# $t->process( $input, $params, $output, $option ) || die $t->error();
#=====================================================================
sub process {
  my $self = shift;
  my $input  = shift || undef;
  my $params = shift || {};
  my $output = shift || undef;
  my $option = shift || {};

  eval {
    my $processor = Template::Like::Processor->new( $self->_option, $params, $option );

    $processor->finalize( $processor->process( $input ), $output );
  };

  $self->error($@);

  die $@ if $@;
  return if $@;
  return 1;
}




#=====================================================================
# error
#---------------------------------------------------------------------
# - API
# $error = $t->error();
#---------------------------------------------------------------------
# - returns
# $error ... Error Message.
#---------------------------------------------------------------------
# - Example
# $t->process( $input, $params, $output, $option ) || die $t->error();
#=====================================================================
sub error  {
  $_[0]->{'ERROR'} = $_[1] if @_ > 1;
  $_[0]->{'ERROR'};
}

sub _option { $_[0]->{'OPTION'}; }

=pod

=head1 NAME

Template::Like - Lightweight Template Engine.

=head1 SYNOPSIS

    #!/usr/bin/perl

    use lib 'lib';
    use strict;
    use Template::Like;

    my $input = q{
    [% var %]
    [% FOREACH var = vars %]
    - [% var.name %]
    [% END %]
    [% var %]
    [% IF bool %]TURE!![% ELSE %]FALSE!![% END %]
    [% UNLESS bool %]TURE!![% ELSE %]FALSE!![% END %]
    };

    my $param = {
      var  => "HOGE",
      vars => [ { name => "FOO" }, { name => "BAR" } ],
      bool => 1
    };

    my $t = Template::Like->new;

    my $output = "";

    $t->process(\$input, $param, \$output);

    print $output;

    exit;


result


    HOGE

    - FOO

    - BAR

    HOGE
    TURE!!
    FALSE!!


=head1 DESCRIPTION

=head2 Directive

=over 4

=item GET

=item SET

=item USE

=item CALL

=item FOREACH

=item WHILE

=item IF

=item UNLESS

=item ELSIF

=item ELSE

=item END

=item FILTER

=item DUMMY

=item INSERT

=item INCLUDE

=item PROCESS

=back

=head2 VMethods

=head3 scalar

=over 4

=item defined

=item length

=item repeat

=item replace

=item match

=item search

=item split

=item list

=item hash

=item size

=item substr

=item html

=item uri

=back

=head3 array

=over 4

=item first

=item last

=item size

=item max

=item reverse

=item join

=item grep

=item sort

=item nsort

=item unshift

=item push

=item shift

=item pop

=item unique

=item merge

=item slice

=item splice

=item list

=back

=head3 hash

=over 4

=item keys

=item values

=item each

=item defined

=item exists

=item size

=item item

=item list

=back

official L<http://www.template-like.org>

=head1 SEE ALSO

L<Template>

=head1 AUTHOR

Shinichiro Aska, E<lt>askadna@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Shinichiro Aska

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
