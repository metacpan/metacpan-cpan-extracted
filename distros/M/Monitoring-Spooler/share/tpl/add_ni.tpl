[% INCLUDE includes/header.tpl %] 

<div class="container">
   <div class="rows">
      <div class="span12">
         <h2>Add Notify Interval</h2>
         <form class="form-inline" method="POST" action="?rm=create_ni">
          <input type="hidden" name="group_id" value="[% group_id %]">
          <select name="type">
            <option value="text">Text</option>
            <option value="phone">Phone</option>
          </select>
          <input type="text" name="from" class="input-small" placeholder="0800">
          <input type="text" name="to"   class="input-small" placeholder="2000">
          <button type="submit" class="btn">Add</button>
         </form>
      </div>
   </div><!-- /rows -->
</div>
[% INCLUDE includes/footer.tpl %]

