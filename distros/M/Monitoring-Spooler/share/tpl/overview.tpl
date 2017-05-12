[% INCLUDE includes/header.tpl %] 

<div class="container">
   <div class="rows">
      <div class="span12">
         <h2>Message Queue</h2>
         <table class="table table-striped">
         <thead>
            <tr>
               <td>Group</td>
               <td>Type</td>
               <td>since</td>
               <td>Message</td>
            </tr>
         </thead>
         <tbody>
         [% FOREACH msg IN msg_queue %]
            <tr>
               <td>[% msg.group_id %]</td>
               <td>[% msg.type %]</td>
               <td>[% msg.ts | localtime %]</td>
               <td>[% msg.message %]</td>
         [% END %]
         </tbody>
         </table>
         <a class="btn btn-danger btn-large" href="?rm=flush_messages&group_id=0">Flush Message Queue(s)</a>
      </div>
   </div><!-- /rows -->
</div>
[% INCLUDE includes/footer.tpl %]

