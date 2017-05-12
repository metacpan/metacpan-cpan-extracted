[% SET action = rd.action || 'quarantine' %]

<form method="POST">
<p>
Currently mail that we think might be spam will be:

	<ul>
	<p>
		<input type="radio" name="new_action" value="drop"
			[% IF action == 'drop' %]checked="1"[% END %]>
		<strong>dropped</strong>
	</p>

	<p>
	<input type="radio" name="new_action" value="forward" 
		[% IF action == 'forward' %]checked="1"[% END %]> 
		<strong>forwarded</strong> to:
		<input type="text" name="new_address" size="60"
			value="[% GET rd.new_address %]">
	</p>

	<p>
	<input type="radio" name="new_action" value="quarantine" 
		[% IF action == 'quarantine' %]checked="1" [% END %]>
		<strong>quarantined</strong> (stored for a while and then discarded).
	</p>
	</ul>

<input type="submit" name="action" value="[% GET config.button_recipient_update %]">
</p>
[% GET hiddenstate %]
</form>

<p>
You are authenticated to this site with a token that was emailed to you.  If you
want the current token invalidated an new one sent, 
<a href="[% GET recipient_url %]?action=[% GET config.button_recipient_replace_token %]">click here</a>.
</p>

