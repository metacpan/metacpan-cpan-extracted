function ajax_links() {

   var load_map = {
      '^/$': 'body',
      '^/project/.*': '#content_area',
      '^/server/.*': '#content_area',
      'default': '#content_area'
   };

   $(document).ready(function() {

      $("a").each(function(id, obj) {

         if($(obj).attr("href") && $(obj).attr('class') != 'bound') {

			$(obj).addClass('bound')
            $(obj).click(function(event) {
               event.preventDefault();
               load_link($(this).attr("href"));
            });
         }
      });

   });

   function load_link(lnk) {
      // get the div where the content should be loaded
      var content_area;
      var nolayout = 1;

      for (var key in load_map) {
         var searcher = new RegExp(key);
         if(searcher.exec(lnk)) {
            console.log("Link must be loaded in: " + load_map[key]);
            content_area = load_map[key];
         }
      }

      if(! content_area) {
         console.log("Error finding div for link. Using default.");
         content_area = load_map["default"];
      }

      if(content_area == "body") {
         nolayout = 0;
         document.location.href = lnk;
      }
      else {
         $(content_area).load(lnk + '?nolayout=' + nolayout, function() {
            ajax_links();
         });
      }
   }
}