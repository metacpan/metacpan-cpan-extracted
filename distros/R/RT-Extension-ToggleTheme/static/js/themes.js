jQuery(function() {
  jQuery('#theme_toggle').on( 'click', function() {

      var comp = jQuery('.elevator-light, .elevator-dark');

      if ( comp.length ) {
          comp.toggleClass( 'elevator-light elevator-dark darkmode' );
          jQuery('#theme_toggle_icon').toggleClass('fa-moon fa-sun');

          jQuery.ajax({
            url: RT.Config.WebPath+'/Helpers/Toggle/Theme',
          });
      }
  });
});
