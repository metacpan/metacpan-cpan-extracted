
use Carp ;

#-------------------------------------------------------------------------------

sub AnyMatch
{
my @regexes = @_ ;

return
	(
	sub
		{
		for my $regex (@regexes)
			{
			$regex =~ s/\%TARGET_PATH\//$_[1]/ ;
			return(1) if $_[0] =~ $regex ;
			}
			
		return(0) ;
		}
	) ;
}

#-------------------------------------------------------------------------------

sub NoMatch
{
my @regexes = @_ ;

return
	(
	sub
		{
		my $matched = 0 ;
		
		for my $regex (@regexes)
			{
			$regex =~ s/\%TARGET_PATH\//$_[1]/ ;
			$matched++ if $_[0] =~ $regex ;
			}
			
		return(0) if $matched ;
		return(1) ;
		}
	) ;
}

#-------------------------------------------------------------------------------

sub AndMatch
{
my @dependent_regex = @_ ;

return
	(
	sub
		{
		for my $dependent_regex (@dependent_regex)
			{
			if('Regexp' eq ref $dependent_regex)
				{
				$dependent_regex  =~ s/\%TARGET_PATH\//$_[1]/ ;
				return(0) unless $_[0] =~ $dependent_regex ;
				}
			elsif('CODE' eq ref $dependent_regex)
				{
				# assume code
				unless($dependent_regex->(@_))
					{
					return(0) ;
					}
				}
			else
				{
				confess() ;
				}
			}
			
		return(1) ;
		}
	) ;
}

#-------------------------------------------------------------------------------

1 ;
