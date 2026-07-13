/**
 *  Fonctions d'alerte de l'utilisateur.
 */

/**
 * Alerte l'utilisateur d'une information
 * @param message Message à afficher.
 */
function infoBox( message )
{
    _displayMessageBox( 'info', message ) ;
}

/**
 * Alerte l'utilisateur d'un disfonctionnement
 * @param message Message à afficher.
 */
function successBox( message )
{
    _displayMessageBox( 'success', message ) ;
}

/**
 * Alerte l'utilisateur d'un évènement
 * @param message Message à afficher.
 */
function warningBox( message )
{
    _displayMessageBox( 'warning', message ) ;
}

/**
 * Alerte l'utilisateur d'un disfonctionnement
 * @param message Message à afficher.
 */
function alertBox( message )
{
    _displayMessageBox( 'danger', message ) ;
}


/**
 *  Affiche la boite d'alerte.
 *  @param level Niveau d'alerte ( sucess, info, warning, danger )
 *  @param message Message d'alerte ( format html )
 */
function _displayMessageBox( level, message )
{
    $('#alert-box span:last').html(message) ;
    var alertContainer = $('#alert-container') ;
    var alertBox = $('#alert-box').clone() ;
    alertBox.addClass('alert-' + level) ;
    alertBox.removeAttr('id') ;
    alertContainer.append(alertBox) ;
    alertContainer.show();
    alertBox.slideDown() ;

    if ( level == "info" || level == "success") {
        alertBox.fadeTo(5000, 500).slideUp(500, function(){
            alertBox.slideUp(500);
        });
    }
}


// Pour construire les boutons d'action dans les datatables
function build_btn( title, classe, style ) {

    btn = '<a href="#" ';
    if ( title ){
        btn = btn + 'title="' + title + '" >';
    }
    else {
        btn = btn + ' >';
    }

    btn = btn + '<span ';
    if ( classe ){
        btn = btn + 'class=" ' + classe +  '" ';
    }

    if ( style ){
        btn = btn + 'style=" ' + style +  '" ';
    }

    btn = btn + '</span></a>';

    return btn;
}

// Permission-aware action button renderer
function renderActions( items, addthis ) {
    var html = '<div class="nowrap">';
    if ( items ) {
        for ( var i = 0; i < items.length; i++ ) {
            var show = true;
            if ( items[i].perm  ) show = show && fondationCheckPerm(items[i].perm);
            if ( items[i].group ) show = show && fondationCheckGroup(items[i].group);
            if ( show ) {
                html += build_btn(items[i].title, items[i].classe, items[i].style) + '&nbsp;';
            }
        }
    }
    return html + (addthis || '') + '</div>';
}
