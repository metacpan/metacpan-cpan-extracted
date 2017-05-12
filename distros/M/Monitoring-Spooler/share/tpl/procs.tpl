[% INCLUDE includes/header.tpl %] 

<div class="container">
   <h1>Running Processes</h1>
   <div class="rows">
      <div class="span12">
         <table class="table table-striped">
         <thead>
            <tr>
               <td>Pid</td>
               <td>Type</td>
               <td>Name</td>
            </tr>
         </thead>
         <tbody>
         [% FOREACH proc IN running_procs %]
            <tr>
               <td>[% proc.pid %]</td>
               <td>[% proc.type %]</td>
               <td>[% proc.name %]</td>
         [% END %]
         </tbody>
         </table>
      </div>
   </div><!-- /rows -->
</div>
[% INCLUDE includes/footer.tpl %]

