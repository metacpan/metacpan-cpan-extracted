
[% IF rd.headers %]

	<table>
	[% FOREACH m = rd.headers %]
		[% IF loop.first %]
			<p>
			The following messages are what we currently have stored up
			waiting to be delivered to you:
			</p>

			<tr><th>FROM</th><th>SUBJECT</th><th>DATE</th></tr>

		[% END %]
		[% IF m.value && ! m.value.done %]
		<tr></td><td
			>[% GET m.value.from %]</td><td
			>[% GET m.value.subject %]</td><td
			>[% GET m.value.date %]</td></tr>
		[% END %]
		[%- "</table>" IF loop.last %]
	[% END %]
[% END %]


