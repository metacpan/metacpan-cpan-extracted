
[% IF otherheaders.0.cksum %]
	<hr>
	Other messages from you...
	<form method="POST">
	<table>
	<tr><th></th><th>TO</th><th>SUBJECT</th><th>DATE</th></tr>
	[% FOREACH oh = otherheaders %]
		[% IF ! oh.done %]
		<tr><td><input type="checkbox" name="cb-[% GET oh.cksum %]"></td><td
			>[% GET oh.to %]</td><td
			>[% GET oh.subject %]</td><td
			>[% GET oh.date %]</td></tr>
		[% END %]
	[% END %]
	<tr><td colspan=4>
	<input type="submit" name="action" value="[% GET config.button_sender_delete_checked %]"> 
	<input type="submit" name="action" value="[% GET config.button_sender_delete_all %]">
	<input type="submit" name="action" value="[% GET config.button_sender_send_checked %]">
	</td></tr>
	</table>
	[% GET hiddenstate %]
	</form>
[% END %]

