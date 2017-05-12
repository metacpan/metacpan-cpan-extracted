// do_really
//
// This function asks the user for confirmation. If confirmed, the user is 
// taken to a given url, otherwise he stays on the current page.
//
// @param string - new url if 'yes'
// @param string - confirmation message
//
function do_really(url, msg) {
    var where_to = confirm(msg);
    if (where_to == true) {
        window.location=url;
    } else {
        window.location="#";
    }
}
