#!/usr/bin/env perl -w
use strict;
use Test::More;
use Net::Redmine;
use Net::Redmine::Connection;
use Net::Redmine::TicketHistory;

my $page_html;
{
    local $/= undef;
    $page_html = <DATA>;
}

no warnings 'redefine';
*Net::Redmine::TicketHistory::_build__ticket_page_html = sub {
    return $page_html;
};
use warnings;

my $conn = Net::Redmine::Connection->new(
    url => 'http://example.com',
    user => 'fake',
    password => 'false'
);

my $history = Net::Redmine::TicketHistory->new(connection => $conn, id => 1, ticket_id => 1216);

plan tests => 1;
is($history->date ."", "2009-06-07T04:05:00");

__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title>test - Bug #1216: t/sd-redmine/basic.t 22 1244180247 - Redmine</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="description" content="Redmine" />
<meta name="keywords" content="issue,bug,tracker" />
<link href="/stylesheets/application.css?1241265710" media="all" rel="stylesheet" type="text/css" />
<script src="/javascripts/prototype.js?1241265710" type="text/javascript"></script>
<script src="/javascripts/effects.js?1241265710" type="text/javascript"></script>
<script src="/javascripts/dragdrop.js?1241265710" type="text/javascript"></script>
<script src="/javascripts/controls.js?1241265710" type="text/javascript"></script>
<script src="/javascripts/application.js?1241265710" type="text/javascript"></script>
<link href="/stylesheets/jstoolbar.css?1241265710" media="screen" rel="stylesheet" type="text/css" />
<!--[if IE]>
    <style type="text/css">
      * html body{ width: expression( document.documentElement.clientWidth < 900 ? '900px' : '100%' ); }
      body {behavior: url(/stylesheets/csshover.htc?1241265710);}
    </style>
<![endif]-->

<!-- page specific tags -->
<script src="/javascripts/calendar/calendar.js?1241265710" type="text/javascript"></script><script src="/javascripts/calendar/lang/calendar-en.js?1241265710" type="text/javascript"></script><script src="/javascripts/calendar/calendar-setup.js?1241265710" type="text/javascript"></script><link href="/stylesheets/calendar.css?1241265710" media="screen" rel="stylesheet" type="text/css" />
    <link href="http://redmine.yra.local/issues/1216.atom?key=1KC3e7zC4hWVIIEALQhJFRv2CrDuhF6ffNuCahJx" rel="alternate" title="test - Bug #1216: t/sd-redmine/basic.t 22 1244180247" type="application/atom+xml" />
    <link href="/stylesheets/scm.css?1241265710" media="screen" rel="stylesheet" type="text/css" />
</head>
<body>
<div id="wrapper">
<div id="top-menu">
    <div id="account">
        <ul><li><a href="/my/account" class="my-account">My account</a></li>
<li><a href="/logout" class="logout">Sign out</a></li></ul>    </div>
    <div id="loggedas">Logged in as <a href="/account/show/1">admin</a></div>
    <ul><li><a href="/" class="home">Home</a></li>
<li><a href="/my/page" class="my-page">My page</a></li>
<li><a href="/projects" class="projects">Projects</a></li>
<li><a href="/admin" class="administration">Administration</a></li>
<li><a href="http://www.redmine.org/guide" class="help">Help</a></li></ul></div>

<div id="header">
    <div id="quick-search">
        <form action="/search/index/test" method="get">
        <a href="/search/index/test" accesskey="4">Search</a>:
        <input accesskey="f" class="small" id="q" name="q" size="20" type="text" />
        </form>

    </div>

    <h1>test</h1>

    <div id="main-menu">
        <ul><li><a href="/projects/test" class="overview">Overview</a></li>
<li><a href="/projects/test/activity" class="activity">Activity</a></li>
<li><a href="/projects/test/issues" class="issues selected">Issues</a></li>
<li><a href="/projects/test/issues/new" accesskey="7" class="new-issue">New issue</a></li>
<li><a href="/projects/test/settings" class="settings">Settings</a></li></ul>
    </div>
</div>

<div class="" id="main">
    <div id="sidebar">

    <h3>Issues</h3>
<a href="/projects/test/issues?set_filter=1">View all issues</a><br />

<a href="/projects/test/issues/report">Summary</a><br />
<a href="/projects/test/changelog">Change log</a><br />





<h3>Planning</h3>
<p><a href="/projects/test/issues/calendar">Calendar</a> | <a href="/projects/test/issues/gantt">Gantt</a></p>






    </div>

    <div id="content">
				<div class="flash notice">Successful update.</div>
        <div class="contextual">
<a href="/issues/1216/edit" accesskey="e" class="icon icon-edit" onclick="showAndScrollTo(&quot;update&quot;, &quot;notes&quot;); return false;">Update</a>
<a href="/issues/1216/time_entries/new" class="icon icon-time-add">Log time</a>
<span id="watcher"><a class="icon icon-fav-off" href="/watchers/watch?object_id=1216&amp;object_type=issue" onclick="new Ajax.Request('/watchers/watch?object_id=1216&amp;object_type=issue', {asynchronous:true, evalScripts:true}); return false;">Watch</a></span>
<a href="/projects/test/issues/1216/copy" class="icon icon-copy">Copy</a>
<a href="/issues/1216/move" class="icon icon-move">Move</a>
<a href="/issues/1216/destroy" class="icon icon-del" onclick="if (confirm('Are you sure ?')) { var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;f.submit(); };return false;">Delete</a>
</div>

<h2>Bug #1216</h2>

<div class="issue status-1 priority-2 created-by-me details">

        <h3>t/sd-redmine/basic.t 22 1244180247</h3>
        <p class="author">
        Added by <a href="/account/show/1">Redmine Admin</a> <a href="/projects/test/activity?from=2009-06-05" title="06/05/2009 01:37 pm">1 day</a> ago.
        Updated less than a minute ago.
        </p>

<table width="100%">
<tr>
    <td style="width:15%" class="status"><b>Status:</b></td><td style="width:35%" class="status">New</td>
    <td style="width:15%" class="start-date"><b>Start:</b></td><td style="width:35%">06/05/2009</td>
</tr>
<tr>
    <td class="priority"><b>Priority:</b></td><td class="priority">Normal</td>
    <td class="due-date"><b>Due date:</b></td><td class="due-date"></td>
</tr>
<tr>
    <td class="assigned-to"><b>Assigned to:</b></td><td>-</td>
    <td class="progress"><b>% Done:</b></td><td class="progress"><table class="progress" style="width: 80px;"><tr><td class="todo" style="width: 100%;"></td></tr></table><p class="pourcent">0%</p></td>
</tr>
<tr>
    <td class="category"><b>Category:</b></td><td>-</td>

    <td class="spent-time"><b>Spent time:</b></td>
    <td class="spent-hours">-</td>

</tr>
<tr>
    <td class="fixed-version"><b>Target version:</b></td><td>-</td>

</tr>
<tr>

</tr>

</table>
<hr />

<div class="contextual">
<a class="icon icon-comment" href="#" onclick="new Ajax.Request('/issues/1216/quoted', {asynchronous:true, evalScripts:true}); return false;">Quote</a>
</div>

<p><strong>Description</strong></p>
<div class="wiki">
<p>t/sd-redmine/basic.t 22 1244180247</p>
</div>






<hr />
<div id="relations">
<div class="contextual">

    <a href="#" onclick="Element.toggle('new-relation-form'); this.blur(); return false;">Add</a>

</div>

<p><strong>Related issues</strong></p>



<form action="/issues/1216/relations/1216" id="new-relation-form" method="post" onsubmit="new Ajax.Request('/issues/1216/relations/1216', {asynchronous:true, evalScripts:true, method:'post', parameters:Form.serialize(this)}); return false;" style="display: none;">


<p><select id="relation_relation_type" name="relation[relation_type]" onchange="setPredecessorFieldsVisibility();"><option value="relates">related to</option>
<option value="duplicates">duplicates</option>
<option value="blocks">blocks</option>
<option value="precedes">precedes</option></select>
Issue #<input id="relation_issue_to_id" name="relation[issue_to_id]" size="6" type="text" />
<span id="predecessor_fields" style="display:none;">
Delay: <input id="relation_delay" name="relation[delay]" size="3" type="text" /> days
</span>
<input name="commit" type="submit" value="Add" />
<a href="#" onclick="Element.toggle('new-relation-form'); this.blur(); return false;">Cancel</a>
</p>

<script type="text/javascript">
//<![CDATA[
setPredecessorFieldsVisibility();
//]]>
</script>

</form>

</div>



<hr />
<div id="watchers">
<div class="contextual">
<a href="#" onclick="new Ajax.Request('/watchers/new?object_id=1216&amp;object_type=issue', {asynchronous:true, evalScripts:true}); return false;">Add</a>
</div>

<p><strong>Watchers</strong></p>




</div>


</div>




<div id="history">
<h3>History</h3>

  <div id="change-1" class="journal">
    <h4><div style="float:right;"><a href="/issues/1216#note-1">#1</a></div>
    <a name="note-1"></a>
		Updated by <a href="/account/show/1">Redmine Admin</a> <a href="/projects/test/activity?from=2009-06-07" title="06/07/2009 04:05 am">7 minutes</a> ago</h4>

    <ul>

    </ul>
    <div class="wiki editable" id="journal-1-notes"><div class="contextual"><a href="#" onclick="new Ajax.Request('/issues/1216/quoted?journal_id=1', {asynchronous:true, evalScripts:true}); return false;" title="Quote"><img alt="Comment" src="/images/comment.png?1241265709" /></a> <a href="#" onclick="new Ajax.Request('/journals/edit/1', {asynchronous:true, evalScripts:true, method:'get'}); return false;" title="Edit"><img alt="Edit" src="/images/edit.png?1241265709" /></a></div><p>Zxczxczxc...</p></div>
  </div>


  <div id="change-2" class="journal">
    <h4><div style="float:right;"><a href="/issues/1216#note-2">#2</a></div>
    <a name="note-2"></a>
		Updated by <a href="/account/show/1">Redmine Admin</a> <a href="/projects/test/activity?from=2009-06-07" title="06/07/2009 04:12 am">less than a minute</a> ago</h4>

    <ul>

    </ul>
    <div class="wiki editable" id="journal-2-notes"><div class="contextual"><a href="#" onclick="new Ajax.Request('/issues/1216/quoted?journal_id=2', {asynchronous:true, evalScripts:true}); return false;" title="Quote"><img alt="Comment" src="/images/comment.png?1241265709" /></a> <a href="#" onclick="new Ajax.Request('/journals/edit/2', {asynchronous:true, evalScripts:true, method:'get'}); return false;" title="Edit"><img alt="Edit" src="/images/edit.png?1241265709" /></a></div><p>How are you.</p></div>
  </div>



</div>

<div style="clear: both;"></div>


  <div id="update" style="display:none;">
  <h3>Update</h3>
  <form action="/issues/1216/edit" enctype="multipart/form-data" id="issue-form" method="post">


    <div class="box">

        <fieldset class="tabular"><legend>Change properties

        <small>(<a href="/issues/1216" onclick="Effect.toggle(&quot;issue_descr_fields&quot;, &quot;appear&quot;, {duration:0.3}); return false;">More</a>)</small>

        </legend>


<div id="issue_descr_fields" style="display:none">
<p><label for="issue_subject">Subject<span class="required"> *</span></label><input id="issue_subject" name="issue[subject]" size="80" type="text" value="t/sd-redmine/basic.t 22 1244180247" /></p>
<p><label for="issue_description">Description</label><textarea accesskey="e" class="wiki-edit" cols="60" id="issue_description" name="issue[description]" rows="10">t/sd-redmine/basic.t 22 1244180247</textarea></p>
</div>

<div class="attributes">
<div class="splitcontentleft">

<p><label>Status</label> New</p>


<p><label for="issue_priority_id">Priority<span class="required"> *</span></label><select id="issue_priority_id" name="issue[priority_id]"><option value="3">Low</option>
<option value="4" selected="selected">Normal</option>
<option value="5">High</option>
<option value="6">Urgent</option>
<option value="7">Immediate</option></select></p>
<p><label for="issue_assigned_to_id">Assigned to</label><select id="issue_assigned_to_id" name="issue[assigned_to_id]"><option value=""></option>
</select></p>


</div>

<div class="splitcontentright">
<p><label for="issue_start_date">Start</label><input id="issue_start_date" name="issue[start_date]" size="10" type="text" value="2009-06-05" /><img alt="Calendar" class="calendar-trigger" id="issue_start_date_trigger" src="/images/calendar.png?1241265709" /><script type="text/javascript">
//<![CDATA[
Calendar.setup({inputField : 'issue_start_date', ifFormat : '%Y-%m-%d', button : 'issue_start_date_trigger' });
//]]>
</script></p>
<p><label for="issue_due_date">Due date</label><input id="issue_due_date" name="issue[due_date]" size="10" type="text" /><img alt="Calendar" class="calendar-trigger" id="issue_due_date_trigger" src="/images/calendar.png?1241265709" /><script type="text/javascript">
//<![CDATA[
Calendar.setup({inputField : 'issue_due_date', ifFormat : '%Y-%m-%d', button : 'issue_due_date_trigger' });
//]]>
</script></p>
<p><label for="issue_estimated_hours">Estimated time</label><input id="issue_estimated_hours" name="issue[estimated_hours]" size="3" type="text" /> Hours</p>
<p><label for="issue_done_ratio">% Done</label><select id="issue_done_ratio" name="issue[done_ratio]"><option value="0" selected="selected">0 %</option>
<option value="10">10 %</option>
<option value="20">20 %</option>
<option value="30">30 %</option>
<option value="40">40 %</option>
<option value="50">50 %</option>
<option value="60">60 %</option>
<option value="70">70 %</option>
<option value="80">80 %</option>
<option value="90">90 %</option>
<option value="100">100 %</option></select></p>
</div>

<div style="clear:both;"> </div>
<div class="splitcontentleft">


</div>
<div style="clear:both;"> </div>

</div>







<script src="/javascripts/jstoolbar/jstoolbar.js?1241265710" type="text/javascript"></script><script src="/javascripts/jstoolbar/textile.js?1241265710" type="text/javascript"></script><script src="/javascripts/jstoolbar/lang/jstoolbar-en.js?1241265709" type="text/javascript"></script><script type="text/javascript">
//<![CDATA[
var toolbar = new jsToolBar($('issue_description')); toolbar.setHelpLink('Text formatting: <a href="/help/wiki_syntax.html" onclick="window.open(&quot;/help/wiki_syntax.html&quot;, &quot;&quot;, &quot;resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes&quot;); return false;">Help</a>'); toolbar.draw();
//]]>
</script>

        </fieldset>


        <fieldset class="tabular"><legend>Log time</legend>

        <div class="splitcontentleft">
        <p><label for="time_entry_hours">Spent time</label><input id="time_entry_hours" label="label_spent_time" name="time_entry[hours]" size="6" type="text" /> Hours</p>
        </div>
        <div class="splitcontentright">
        <p><label for="time_entry_activity_id">Activity</label><select id="time_entry_activity_id" name="time_entry[activity_id]"><option value="">--- Please select ---</option>
<option value="8">Design</option>
<option value="9">Development</option></select></p>
        </div>
        <p><label for="time_entry_comments">Comment</label><input id="time_entry_comments" name="time_entry[comments]" size="60" type="text" /></p>


    </fieldset>


    <fieldset><legend>Notes</legend>
    <textarea class="wiki-edit" cols="60" id="notes" name="notes" rows="10"></textarea>
    <script src="/javascripts/jstoolbar/jstoolbar.js?1241265710" type="text/javascript"></script><script src="/javascripts/jstoolbar/textile.js?1241265710" type="text/javascript"></script><script src="/javascripts/jstoolbar/lang/jstoolbar-en.js?1241265709" type="text/javascript"></script><script type="text/javascript">
//<![CDATA[
var toolbar = new jsToolBar($('notes')); toolbar.setHelpLink('Text formatting: <a href="/help/wiki_syntax.html" onclick="window.open(&quot;/help/wiki_syntax.html&quot;, &quot;&quot;, &quot;resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes&quot;); return false;">Help</a>'); toolbar.draw();
//]]>
</script>


    <p>Files<br /><span id="attachments_fields">
<input name="attachments[1][file]" size="30" type="file" /><input name="attachments[1][description]" size="60" type="text" value="" />
<em>Optional description</em>
</span>
<br />
<small><a href="#" onclick="addFileField(); return false;">Add another file</a>
(Maximum size: 5 MB)
</small>
</p>
    </fieldset>
    </div>

    <input id="issue_lock_version" name="issue[lock_version]" type="hidden" value="2" />
    <input name="commit" type="submit" value="Submit" />
    <a accesskey="r" href="#" onclick="new Ajax.Updater('preview', '/issues/preview/1216?project_id=test', {asynchronous:true, evalScripts:true, method:'post', onComplete:function(request){Element.scrollTo('preview')}, parameters:Form.serialize(&quot;issue-form&quot;)}); return false;">Preview</a>
</form>

<div id="preview" class="wiki"></div>

  </div>


<p class="other-formats">Also available in:
	<span><a href="/issues/1216.atom?key=1KC3e7zC4hWVIIEALQhJFRv2CrDuhF6ffNuCahJx" class="atom" rel="nofollow">Atom</a></span>
	<span><a href="/issues/1216.pdf" class="pdf" rel="nofollow">PDF</a></span>
</p>








				<div style="clear:both;"></div>
    </div>
</div>

<div id="ajax-indicator" style="display:none;"><span>Loading...</span></div>

<div id="footer">
    Powered by <a href="http://www.redmine.org/">Redmine</a> &copy; 2006-2009 Jean-Philippe Lang
</div>
</div>

</body>
</html>
