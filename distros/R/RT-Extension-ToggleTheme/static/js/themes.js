jQuery(function() {
  jQuery('#theme_toggle').on('click', function() {
    var html     = jQuery('html');
    var newTheme = html.attr('data-bs-theme') === 'dark' ? 'light' : 'dark';
    html.attr('data-bs-theme', newTheme);
    jQuery.ajax({ url: RT.Config.WebPath + '/Helpers/Toggle/Theme' });
  });
});
