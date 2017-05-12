[% SET action = psender.action || 'quarantine' %]

<form method="POST">
<p>
Currently when you send mail that we think might be spam, we should:
	<ul>
	<p>
		<input type="radio" name="new_action" value="discard"
			[% IF action == 'discard' %]checked="1"[% END %]>
		<strong>discard</strong> it without a bounce.
	</p>

	<p>
		<input type="radio" name="new_action" value="bounce"
			[% IF action == 'bounce' %]checked="1"[% END %]>
		<strong>bounce</strong> it.
	</p>

	<p>
	<input type="radio" name="new_action" value="quarantine" 
		[% IF action == 'quarantine' %]checked="1" [% END %]>
		<strong>quarantine</strong> it (store it for a while and then discard it later
		if you haven't visited this site and said what to do with it).
	</p>
	</ul>

[% SET pbounce = psender.renotify_days || config.renotify_sender_ip %]

When we quarantine or bounce mail, we limit the number of bounces we
send.  How often should we send a bounce message?


	<ul>
	<p>
	every
	<input type="text" name="renotify_days" value="[% GET pbounce %]" size="4"> 
	days
	</p>
	</ul>

<input type="submit" name="action" value="[% GET config.button_sender_update %]">
<input type="submit" name="action" value="[% GET config.button_sender_reset_timer %]">
</p>
[% GET hiddenstate %]
</form>

<p>
You are authenticated to this site with a token that was emailed to you.  If you
want the current token invalidated an new one sent, 
<a href="[% GET sender_url %]?action=[% GET config.button_sender_replace_token %]">click here</a>.
</p>

