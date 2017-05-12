
[% IF header.time && ! header.done %]

	<form method="POST">
	<table>
	<tr><th align=left>From:</th><td>[% GET header.from %]</td></tr>
	<tr><th align=left>To:</th><td>[% GET header.to %]</td></tr>
	<tr><th align=left>Subject:</th><td>[% GET header.subject %]</td></tr>
	<tr><th align=left>Date:</th><td>[% GET header.date %]</td></tr>
	<tr><td><input 
		type="submit" name="action" 
		value="[% GET config.button_sender_delete %]"></td><td><input 
		type="submit" name="action" value="[% GET config.button_sender_send %]"></td></tr>
	</table>
	[% GET hiddenstate %] 
	</form>

[% END %]

