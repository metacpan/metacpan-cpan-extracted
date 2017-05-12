[% USE date(format = '%d.%m.%y %H:%M:%S', locale = 'de_DE') %]
<html>
    <head>
        <meta charset="utf-8" />
        <link rel="stylesheet" type="text/css" href="css/default.css" media="all" />
        <meta http-equiv="refresh" content="[% refresh %]" />
        <meta name="viewport" content="initial-scale=1.0">
    </head>
    <body onload="setTimeout(function(){ alert('No refresh for 30 minutes!'); }, 30 * 60 * 1000);">
        [% IF triggers.size > 0 %]
        [% FOREACH trigger IN triggers %]
        <div class="trigger [% trigger.severity %][% IF trigger.acknowledged %] acknowledged[% END %]">
            <div class="field severity">[% trigger.severity | ucfirst %]</div>
            <div class="field icon">
                [% IF trigger.acknowledged %]
                <div title="ACKed on [% trigger.eventclock | localtime %] by [% trigger.user %]">
                  <div class="icon acked"></div>
                </div>
                [% ELSE %]
                <div class="icon noack"></div>
                [% END %]
            </div>
            <div class="field host">[% trigger.host %]</div>
            <div class="field name">[% trigger.description %]</div>
            <div class="field time">since [% trigger.lastchange | localtime %]</div>
            <div class="field button"><!-- placeholder for details button --></div>
            <div class="field lastvalue">Val=[% trigger.lastvalue %]</div>
            <div class="clear"></div>
            <div class="details">[% trigger.comments %]</div>
        </div>
        [% END %]
        [% ELSE %]
        <div class="allgreen">No errors. All good. Relax.<br /><div class="smiley">&#x263A;</div></div>
        [% END %]
        <br />
        <div class="lastupdate">
                Last update: [% date.format %]
        </div>
    </body>
</html>
