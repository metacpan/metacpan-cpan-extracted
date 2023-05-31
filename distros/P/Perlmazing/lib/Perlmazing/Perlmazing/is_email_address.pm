use Perlmazing;

sub main {
	return 0 unless $_[0];
	return (wantarray ? ($1, $2) : 1) if length($_[0]) <= 254 and $_[0] =~ /
		# Make captures for user and domain only ($1 and $2), using (?: on any other parenthesis to avoid captures
		^
			( # Begin first part of email address
				(?: # Option 1
					[^<>()[\]\\.,;:\s@\"]+ # Any character NOT in this set, at least one
					(?:
						\.[^<>()[\]\\.,;:\s@\"]+ # Followed by any character NOT in these set, starting with dot, in groups from 0 to many
					)*
				)
				|
				(?: # Option 2
					".*?(?<!\\)" # Anything between double quotes, including escaped double quotes
				)
			)
			[ ]*@[ ]*
			( # Beginning of second part of email address (domain name or ip address)
				(?:
					\[ # If IP address, accepted only between brackets
						(?: # First group cannot begin in zero. From 1 to 255
							[1-9]			# If it's only one char, from 1 to 9
							|
							[1-9][0-9]		# If it's 2 chars, from 10 to 99
							|
							[1][0-9][0-9]	# If it's 3 chars, from 100 to 199
							|
							[2][0-4][0-9]	# If it's 3 chars, from 200 to 249
							|
							[2][5][0-5]		# If it's 3 chars, from 250 to 255
						)
						\.	# Separating dot
						(?: # Second and third groups can start in zero. From 0 to 255
							(?:
								[0-9]			# If it's only one char, from 0 to 9
								|
								[1-9][0-9]		# If it's 2 chars, from 10 to 99
								|
								[1][0-9][0-9]	# If it's 3 chars, from 100 to 199
								|
								[2][0-4][0-9]	# If it's 3 chars, from 200 to 249
								|
								[2][5][0-5]		# If it's 3 chars, from 250 to 255
							)
							\.	# Separating dot
						){2}	# This must be present 2 times
						(?: # Fourth group cannot begin in zero and cannot end in 255. From 1 to 254
							[1-9]			# If it's only one char, from 1 to 9
							|
							[1-9][0-9]		# If it's 2 chars, from 10 to 99
							|
							[1][0-9][0-9]	# If it's 3 chars, from 100 to 199
							|
							[2][0-4][0-9]	# If it's 3 chars, from 200 to 249
							|
							[2][5][0-4]		# If it's 3 chars, from 250 to 254
						)
						# No dot here
					\]
				)
				|
				(?: # If domain, accept only groups of alphanumeric chars, can contain dashes only between chars
					(?:	# First part also must have a dot for one to n parts
						(?:
							[a-zA-Z0-9]{1,2} # If it's one or two chars
							|
							[a-zA-Z0-9][a-zA-Z0-9\-]+[a-zA-Z0-9] # If it's 3 or more chars
						)
						\. # Trailing dot
					)+	# One or more times the same
					[a-zA-Z]{2,} # It must end with only letters, from 2 to n
				)
			)
		$
	/x and length($1) <= 64;
	return 0;
}

1;
