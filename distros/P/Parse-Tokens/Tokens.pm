package Parse::Tokens;

# $Id: Tokens.pm,v 1.5 2001/11/28 01:14:55 steve Exp $

# Copyright 2000-2001 by Steve McKay. All rights reserved.
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use vars qw( $VERSION  );

$VERSION = 0.27;

sub new
{
	my ( $proto, $params ) = @_;
	my $class = ref($proto) || $proto;
	my $self = {
		debug => undef,
		text => undef,
		autoflush => undef,
		loose_paring => undef,
		pre_callback => undef,
		post_callback => undef,
		token_callback => undef,
		ether_callback => undef,
		delimiters => [],
		delim_index => {},
	};
	bless( $self, $class );
	$self->init( $params );
	$self;
}

sub init
{
    my( $self, @args ) = @_;
	no strict 'refs';
	$self->_msg( "Processing initialization arguments." );
	for ( keys %{$args[0]} )
	{
		my $ref = lc $_;
		$self->$ref( $args[0]->{$_} );
	}
	use strict;
}

sub debug
{
	my( $self, @args ) = @_;
	$self->_msg( "Storing 'debug' prefs." );
	$self->{'debug'} = $args[0] if defined $args[0];
	return $self->{'debug'};
}

sub token_callback
{
	my( $self, @args ) = @_;
	$self->_msg( "Storing 'token_callback' prefs." );
	$self->{'token_callback'} = $args[0] if defined $args[0];
	return $self->{'token_callback'};
}

sub ether_callback
{
	my( $self, @args ) = @_;
	$self->_msg( "Storing 'ether_callback' prefs." );
	$self->{'ether_callback'} = $args[0] if defined $args[0];
	return $self->{'ether_callback'};
}

sub pre_callback
{
	my( $self, @args ) = @_;
	$self->_msg( "Storing 'pre_callback' prefs." );
	$self->{'pre_callback'} = $args[0] if defined $args[0];
	return $self->{'pre_callback'};
}

sub post_callback
{
	my( $self, @args ) = @_;
	$self->_msg( "Storing 'post_callback' prefs." );
	$self->{'post_callback'} = $args[0] if defined $args[0];
	return $self->{'post_callback'};
}

sub loose_paring
{
	my( $self, @args ) = @_;
	$self->_msg( "Storing 'loose_paring' prefs." );
	$self->{'loose_paring'} = $args[0] if defined $args[0];
	return $self->{'loose_paring'};
}

sub autoflush
{
	my( $self, @args ) = @_;
	$self->_msg( "Storing 'autoflush' prefs." );
	$self->{'autoflush'} = $args[0] if defined $args[0];
	return $self->{'autoflush'};
}

sub text
{
	my( $self, @args ) = @_;
	$self->_msg( "Storing 'text'." );
	$self->flush();
	$self->{'text'} = $args[0] if defined $args[0];
	return $self->{'text'};
}

sub delimiters
{
	my( $self, @args ) = @_;
	# we currently support both a ref to an array of delims
	# as well as an ref to an array of array refs with delims
	if ( ref($args[0]) eq 'ARRAY' )
	{
		# wipe our existing delimiters
		$self->{'delimiters'} = [];
		# we have multiple arrays
		if( ref($args[0]->[0]) eq 'ARRAY' )
		{
			for( @{$args[0]} )
			{
				$self->push_delimiters( $_ );
			}	
		}
		# we have only this array ref
		else
		{
			$self->push_delimiters( $args[0] );
		}
	}
	return @{$self->{'delimiters'}};
}

*add_delimiters = \&push_delimiters;
sub push_delimiters
{ 
	# add a delim pair (real and quoted) to the delimiters array
	my( $self, @args ) = @_;
	$self->_msg( "Adding delimiter pair." );
	if( ref($args[0]) eq 'ARRAY' )
	{
		push(
			@{$self->{'delimiters'}}, {
				real	=> $args[0],
				quoted	=> [
					quotemeta($args[0]->[0]),
					quotemeta($args[0]->[1])
				]
			}
		);
		$self->{'delim_index'}->{$args[0]->[0]} = $#{$self->{delimiters}};
		$self->{'delim_index'}->{$args[0]->[1]} = $#{$self->{delimiters}};
	}
	else
	{
		warn "Args to push_delimiter not an array reference";
	}
	return 1;
}

sub flush
{
	my( $self ) = @_;
	$self->_msg( "Flushing cached parts." );
	delete $self->{'cache'};
	return 1;
}

sub parse
{
	my( $self, @args ) = @_;
	$self->pre_parse();
	$self->init( $args[0] );
	return unless defined $self->{'text'};
	$self->flush() if $self->{'autoflush'};

	my @delim = $self->delimiters();
	my $match_rex = $self->match_expression( \@delim );

	unless( $self->{'cache'} )
	{
		# parse the text
		$self->_msg( "Data not cached. Parsing text." );
		my @chunk = split( m/$match_rex/s, $self->{'text'} );
		@{$self->{'cache'}} = @chunk;
	}

	$self->_msg( "Processing parsed text parts." );
	my $n = 0;
	while ($n <= $#{$self->{'cache'}})
	{
		# find opening delimiter
		
		# if the first element of the token is the element of a token
		#if ( $self->{cache}->[$n] eq $delim[0]->{real}->[0] || $self->{cache}->[$n] eq $delim[1]->{real}->[0] )
		if ( $self->{'cache'}->[$n] eq $delim[$self->{'delim_index'}->{$self->{'cache'}->[$n]}]->{'real'}->[0] )
		{
			$self->_msg( "Dispatching token." );
			$self->token([
				$self->{'cache'}->[$n],
				$self->{'cache'}->[++$n],
				$self->{'cache'}->[++$n]
			]);
		}

		# or it's just text
		else
		{
			$self->_msg( "Dispatching text." );
			$self->ether( $self->{'cache'}->[$n] );
		}
		$n++
	}
	$self->post_parse();
}

sub match_expression
{
	# construct our token finding regular expression
	my( $self, $delim ) = @_;
	my $rex;
	if( $self->{'loose_paring'} )
	{
		my( @left, @right );
		for( @$delim )
		{
			push( @left, $_->{'quoted'}->[0] );
			push( @right, $_->{'quoted'}->[1] );
		}
		$rex = '('.join('|', @left).')(.*?)('.join('|', @right).')';
	}
	else
	{
		my( @sets );
		for( @$delim )
		{
			push( @sets, qq{($_->{'quoted'}->[0])(.*?)($_->{'quoted'}->[1])} );
		}
		$rex = join( '|', @sets );
	}
	$self->_msg( "Constructed '$rex' pattern matching expression." );
	$self->{'match_expression'} = $rex;
	return $rex;
}

# a token consists of a left-delimiter, the contents, and a right-delimiter
*atom = \&token;
sub token
{
	my( $self, $token ) = @_;
	$self->_msg( "Found token ", join( ', ', @$token ) );
	if( $self->{'token_callback'} )
	{
		$self->_msg( "Dispatching token to callback handler '$self->{'token_callback'}'." );
		no strict 'refs';
		&{$self->{'token_callback'}}( $token );
		use strict;
	}
	else
	{
		$self->_msg( "Consider overriding my 'token' method." );
	}
	return 1;
}

# ether is anything not contained in an atom
sub ether
{
	my( $self, $text ) = @_;
	$self->_msg( "Found text ", $text );
	if( $self->{'ether_callback'} )
	{
		$self->_msg( "Dispatching text to callback handler '$self->{'ether_callback'}'." );
		no strict 'refs';
		&{$self->{'ether_callback'}}( $text );
		use strict;
	}
	else {
		$self->_msg( "Consider overriding my 'ether' method." );
	}
	return 1;
}

# this is called just before parsing begins
sub pre_parse
{
	my( $self ) = @_;
	if( $self->{'pre_callback'} )
	{
		$self->_msg( "Dispatching pre_parse event to callback handler '$self->{'pre_callback'}'." );
		no strict 'refs';
		&{$self->{'pre_callback'}}();
		use strict;
	}
	else
	{
		$self->_msg( "Consider overriding my 'pre_parse' method." );
	}
	return 1;
}


# this is called just after parsing ends
sub post_parse
{
	my( $self ) = @_;
	if( $self->{'post_callback'} )
	{
		$self->_msg( "Dispatching post_parse event to callback handler '$self->{'post_callback'}'." );
		no strict 'refs';
		&{$self->{'post_callback'}}();
		use strict;
	}
	else
	{
		$self->_msg( "Consider overriding my 'post_parse' method." );
	}
	return 1;
}

sub _msg
{
	my( $self, @msg ) = @_;
	if( $self->{'debug'} )
	{
		warn __PACKAGE__, ' - ', @msg;
	}
	return 1;
}

1;

__END__

=head1 NAME

Parse::Tokens - class for parsing text with embedded tokens

=head1 SYNOPSIS

  package MyParser;
  use base 'Parse::Tokens';

  MyParser->new->parse({
      text => q{Hi my name is <? $name ?>.},
      hash => {name=>'John Doe'},
      delimiters => [['<?','?>']],
  });

  # override SUPER::token
  sub token
  {
      my( $self, $token ) = @_;
      # $token->[0] - left bracket
      # $token->[1] - contents
      # $token->[2] - right bracket
      # do something with the token...
  }

  # override SUPER::token
  sub ether
  {
      my( $self, $text ) = @_;
      # do something with the text...
  }


=head1 DESCRIPTION
C<Parse::Tokens> provides a base class for parsing delimited strings from text blocks. Use C<Parse::Tokens> as a base class for your own module or script. Very similar in style to C<HTML::Parser>.



=head1 METHODS

=over 10

=item new()

  Pass parameter as a hash reference.
  Options are specified in the getter/setter methods.


=item flush()

  Flush the template cash.


=item parse()

  Run the parser.


=back



=head1 SETTER/GETTER METHODS

=over 10


=item autoflush()

  Turn on autoflushing causing the template cash (not the text) to be purged before each call to parse();.


=item delimiters()

  Specify delimiters as an array reference pointing to the left and right delimiters. Returns array reference containing two array references of delimiters and escaped delimiters.


=item debug()

  Turn on debug mode. 1 is on, 0 is off.


=item ether_callback()

  Sets/gets the callback code reference for the 'ether' event.


=item loose_paring()

  Allow any combination of delimiters to match. Default is turned of requiring exactly specified pair matches only.


=item post_callback()

  Sets/gets the callback code reference for the 'post_parse' event.


=item pre_callback()

  Sets/gets the callback code reference for the 'pre_parse' event.


=item push_delimiters()

  Add a delimiter pair (array ref) to the list of delimiters.
 

=item text()

  Load text.


=item token_callback()

  Sets/gets the callback code reference for the 'token' event.

=back



=head1 EVENT METHODS

=over 10


=item ether()

  Event method that gets called when non-token text is encountered during parsing.


=item post_parse()

  Event method that gets called after parsing has completed.


=item pre_parse()

  Event method that gets called prior to parsing commencing.


=item token()

  Event method that gets called when a token is encountered during parsing.

=back


=head1 HISTORY

=item 0.26

  Cleanup of internal documentation.

=item 0.25

  Added support for callbacks.
  Improved debug messaging.
  Fixed bug in delimiter assignment.
  Rearranged distribution files.

=item 0.24

  Added sample script and sample data.

=item 0.23

  Fixed pseudo bug relation to regular expression 'o' option.
  Aliased 'add_delimiters' to 'push_delimiters'.
  Misc internal changes.

=item 0.22

  Add push_delimiters method for adding to the delimiter array.

=item 0.21

  Add pre_parse and post_parse methods; add minimal debug message support.

=item 0.20

  Add multi-token support.

=head1 AUTHOR

Steve McKay, steve@colgreen.com

=head1 COPYRIGHT

Copyright 2000-2001 by Steve McKay. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

perl(1).

=cut

