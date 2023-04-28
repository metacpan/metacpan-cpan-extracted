package POE::Component::SmokeBox::Smoker;
$POE::Component::SmokeBox::Smoker::VERSION = '0.56';
#ABSTRACT: encapsulates a smoker object.

use strict;
use warnings;
use Params::Check qw(check);
use base qw(Object::Accessor);
use vars qw($VERBOSE);

sub new {
  my $package = shift;

  my $tmpl = {
	perl => { defined => 1, required => 1 },
	env  => { defined => 1, allow => [ sub { return 1 if ref $_[0] eq 'HASH'; } ], },
	do_callback => { allow => sub { return 1 if ! defined $_[0] or $_[0]->isa( 'CODE' ); }, },
	name => { allow => sub { return 1; }, },
  };

  my $args = check( $tmpl, { @_ }, 1 ) or return;
  my $self = bless { }, $package;
  my $accessor_map = {
	perl => sub { defined $_[0]; },
	env  => sub { return 1 if ref $_[0] eq 'HASH'; },
	do_callback => sub { return 1 if ! defined $_[0] or $_[0]->isa( 'CODE' ) },
	name => sub { return 1; },
  };
  $self->mk_accessors( $accessor_map );
  $self->$_( $args->{$_} ) for keys %{ $args };
  return $self;
}

sub dump_data {
  my $self = shift;
  my @returns = qw(perl);
  foreach my $data ( qw( env do_callback ) ) {
    push @returns, $data if defined $self->$data;
  }
  return map { ( $_ => $self->$_ ) } @returns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Smoker - encapsulates a smoker object.

=head1 VERSION

version 0.56

=head1 SYNOPSIS

  use POE::Component::SmokeBox::Smoker;

  my $smoker = POE::Component::SmokeBox::Smoker->new(
	perl => '/home/foo/perl-5.10.0/bin/perl',
	env  => { APPDATA => '/home/foo/perl-5.10.0/', },
  );

  print $smoker->perl();
  my $hashref = $smoker->env();

=head1 DESCRIPTION

POE::Component::SmokeBox::Smoker provides an object based API for SmokeBox smokers. A smoker is defined as
the path to a C<perl> executable that is configured for CPAN Testing and its associated environment settings.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Component::SmokeBox::Smoker object. Takes some parameters:

  'perl', the path to a suitable perl executable, (required);
  'env', a hashref containing %ENV type environment variables;
  'do_callback', a callback to be triggered before+after smoking a job;
  'name', anything you want to attach to the smoker for informative purposes;

=back

=head1 METHODS

=over

=item C<perl>

Returns the C<perl> executable path that was set.

=item C<env>

Returns the hashref of %ENV settings, if applicable.

=item C<do_callback>

Using this enables the callback mode. USE WITH CAUTION!

You need to pass a subref to enable it, and a undef value to disable it. A typical subref would be one you get from POE:

	POE::Component::SmokeBox::Smoker->new(
		'do_callback'	=> $_[SESSION]->callback( 'my_callback', @args ),
		'perl'		=> $^X,
	);

Again, it is worth reminding you that you need to read L<POE::Session> for the exact semantics of callbacks in POE. You do not need
to supply POE callbacks, any plain subref will do.

	POE::Component::SmokeBox::Smoker->new(
		'do_callback'	=> \&my_callback,
		'perl'		=> $^X,
	);

The callback will be executed before+after this smoker object processes a job. In the "BEFORE" phase, you can return a true/false
value to control SmokeBox's actions. If a false value is returned, the smoker will NOT execute the job. It will simply submit the
result as usual, but with some "twists" to the result. The result will have a status of "-1" to signify it didn't run and the "cb_kill"
key will be set to 1. In the "AFTER" phase, the return value doesn't matter because the job is done.

Before a job, the callback will get the data shown. ( $self is a L<POE::Component::SmokeBox::Backend> object! )

	$callback->( 'BEFORE', $self );

After a job, the callback will get the data shown. ( $result is the result hashref you would get from SmokeBox normally )

	$callback->( 'AFTER', $self, $result );

The normal flow for a job would be something like this:

	* submit job to SmokeBox from your session
	* SmokeBox gets ready to process job
	* callback executed with BEFORE
	* SmokeBox processes job
	* callback executed with AFTER
	* SmokeBox submits results to your session

Now, if you have N smokers, it would look like this:

	* submit job to SmokeBox from your session
	* SmokeBox gets ready to process job
	* callback executed with BEFORE ( for smoker 1 )
	* SmokeBox processes job ( for smoker 1 )
	* callback executed with AFTER ( for smoker 1 )
	* callback executed with BEFORE ( for smoker N+1 )
	* SmokeBox processes job ( for smoker N+1 )
	* callback executed with AFTER ( for smoker N+1 )
	* SmokeBox submits results to your session

=item C<dump_data>

Returns all the data contained in the object as a list.

=back

=head1 SEE ALSO

L<POE::Component::SmokeBox>

L<POE::Component::SmokeBox::JobQueue>

L<POE::Component::SmokeBox::Backend>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
