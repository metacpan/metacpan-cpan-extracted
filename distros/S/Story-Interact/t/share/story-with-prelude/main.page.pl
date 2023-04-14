my $bob = npc( 'bob' );

text qq{
	You greet Bob.
	
	Bob says, "@{[ $bob->introduction ]}".
};
