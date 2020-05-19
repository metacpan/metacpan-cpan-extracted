
/* js for Mojolicious Plugin 'Tables' Framework.
 * Most of this is about ajax integration with 'DataTables' ( see datatables.net ).
 * More comments coming Real Soon Now.
 */

function ajaxerror(error) {
    // a native xhr does not auto-parse its responseJSON.
    console.log("ajax fail: " + error.status + ': ' + error.statusText);
    var e_json = error.responseText || '{}';
    var e;
    try { e=JSON.parse(e_json) } catch(parse_err) { e={error:parse_err} }
    var msg = e && e.error? e.error: 'problems with server';
    $('#status-line').text(msg);
}

// as per http://datatables.net/reference/option/dom .. with a div for (B)uttons added;
// although since we have more than 1 group we will append manually.
var dtJqUiDom =
    '<"fg-toolbar ui-toolbar ui-widget-header ui-helper-clearfix ui-corner-tl ui-corner-tr"' +
        '<"zone1 ui-helper-clearfix">' +
        '<"zone2 ui-helper-clearfix" frip>' +
    '>t';

function saveState(s,d){ localStorage.setItem('DataTables_'+s.sInstance,JSON.stringify(d)) }
function loadState(s)  { var d=JSON.parse(localStorage.getItem('DataTables_'+s.sInstance));
                         if (!d) return;
                         d.columns[1].search.search = '';
                         return d }

var $dtTable, dtTable, dtTableTabName;

function dtTableSaveState(s,d){ localStorage.setItem('DTTable_'+dtTableTabName,JSON.stringify(d)) }
function dtTableLoadState(s)  { return JSON.parse(localStorage.getItem('DTTable_'+dtTableTabName)) }

var dtJqUiTableDom =
    '<"fg-toolbar ui-toolbar ui-widget-header ui-helper-clearfix ui-corner-tl ui-corner-tr"' +
        '<"zone2 ui-helper-clearfix" Bfrip>' +
    '>t';

var dtTabInfo;
function colmaker(column,i) {
    var colinfo = dtTabInfo.bycolumn[column];
    if (colinfo.fkey) return { // this is the parent object, stringified
            visible: true,
            data:    column,
            title:   '('+colinfo.label+')',
            orderable: false
        };
    return {
        visible: !colinfo.is_auto_increment && !colinfo.is_foreign_key,
        data:    column,
        title:   colinfo.label
    };
}

function tables() {
    var $this = $(this);
    dtTableTabName = $this.attr('table');
    $dtTable  = $('table#data-table');
    $('#tablesbuts button').removeClass('ui-state-highlight');
    $this.addClass('ui-state-highlight');
    $('.data-hdr h3').text($this.text());
    $('#tablesbody button.add').button('enable').click(function(){ document.location = shipped.urlbase + '/tables/' + dtTableTabName + '/add' });
    dtTabInfo = shipped.bytable[dtTableTabName];
    var columns = $.map(dtTabInfo.columns, colmaker);
    //console.log("genned columns struct ", columns);
    if (dtTable) {
        dtTable.destroy();
        $dtTable.empty();
    }
    dtTable = $dtTable.DataTable({
                dom: dtJqUiTableDom,
                buttons: [ 'columnsToggle'],
                columns: columns,
                serverSide: true,
                ajax: (document.location.pathname + '/' + dtTableTabName + '.json'),
                stateSave: true,
                stateSaveCallback: dtTableSaveState,
                stateLoadCallback: dtTableLoadState
            });
    $('.accordion').accordion('option', 'active', 0);
    dtTableEvents();
    dtTable.on('draw', dtTableEvents);
}

function dtTableEvents() {
    $('tbody tr', $dtTable).hover(
        function(){$(this).css({cursor:'pointer','font-weight':'normal'}).addClass('ui-state-active')},
        function(){$(this).css({cursor:''}).removeClass('ui-state-active')}
    ).on('click',
        function(){document.location = shipped.urlbase + '/tables/' + dtTableTabName + '/' + $(this).attr('id') + '/view'}
    );
}

function enable_buts($fldset) {
    var cdata = $fldset.data();
    var $buts = $fldset.find('div.stats button');
    if (cdata.total <= 10) $buts.button('disable');
    else {
        // strange or'd conditions here can only apply when full(>10) list showing; effect is revert to paged.
        $buts.filter('.start').button(cdata.offset>0 || cdata.to==cdata.total  ? 'enable': 'disable');
        $buts.filter('.prev' ).button(cdata.offset>0                           ? 'enable': 'disable');
        $buts.filter('.next' ).button(cdata.to<cdata.total                     ? 'enable': 'disable');
        $buts.filter('.end'  ).button(cdata.offset==0 || cdata.to<cdata.total  ? 'enable': 'disable');
    }
    // re-enable add-butt unless on delete-verify page
    if ($('div#tablesbody.del').length==0) $buts.filter('.add').button('enable');
}

var session = {}, shipped = {};

function init() {

    session = JSON.parse($('#session').html());
    shipped = JSON.parse($('#shipped').html());
    console.log("session %o, shipped %o", session, shipped);

    if (shipped.logourl) {
        $('#header a#logo').css('background', 'url('+shipped.logourl+')');
    }

    $('.button').each(function(i){
        var $this = $(this);
        var icon1 = $this.data('icon1');
        var icon2 = $this.data('icon2');
        if (!icon1 && !icon2) return $this.button();
        var keeptext = !$this.hasClass('notxt');
        $this.button({icons:{primary:icon1,secondary:icon2},text:keeptext});
    });

    $('.accordion').accordion({
        heightStyle: "content"
    });

    $('#tablesbuts button').click(tables);
    if (shipped.start_with) $('#tablesbuts button[table='+shipped.start_with+']').click();
                    else $('#tablesbody .data-hdr button.add').button('disable');

    $('.picklist').selectmenu();

    $('div.navigators button').click(function(){
        var $this = $(this);
        if ($this.hasClass('save' )) return true; // allows post to proceed
        var newloc = shipped.urlbase + '/tables/' + shipped.table;
        if ($this.hasClass('list' )) {
            document.location = newloc;
            return;
        }
        if ($this.hasClass('add' )) {
            document.location = newloc + '/add';
            return;
        }
        newloc += '/' + shipped.id;
        var more;
        $.each(['view','edit','del','nuke'], function(i,act) {
            if ($this.hasClass(act)) more = act
        });
        if (more) {
            document.location = newloc + '/' + more;
            return false;
        }

        $.each(['prev','start','next','end'], function(i,nav) {
            if ($this.hasClass(nav)) more = nav
        });
        if (more) document.location = newloc + '/navigate?to=' + more;
        return false;
    });

    $('fieldset.group').each(function(){
        var $fldset    = $(this);
        var cdata      = $fldset.data();
        cdata.offset   = 0;
        cdata.from     = 1;
        $fldset.find('div.stats button').click(function() {
            var $this = $(this);
            if ($this.hasClass('add'  )) {
                var href = '/tables/' + shipped.table + '/' + shipped.id + '/add_child/' + cdata.collection;
                document.location = shipped.urlbase + href;
                return false;
            }
            if ($this.hasClass('prev' )) cdata.offset = cdata.offset<10? 0: cdata.offset-10;
            if ($this.hasClass('start')) cdata.offset = 0;
            if ($this.hasClass('next' )) cdata.offset += 10;
            if ($this.hasClass('end'  )) cdata.offset = -1;
            if ($this.hasClass('list' )) cdata.offset = -2;
            var url = shipped.urlbase + '/tables/' + shipped.table + '/' + shipped.id + '/' + cdata.collection + '.json';
            $.post(url, {offset:cdata.offset})
             .done(function(rows){
                $('table.rows', $fldset).empty().append(
                    $.map(rows, function(d,i){
                        var href = shipped.urlbase + '/tables/' + cdata.ctable + '/' + d.id + '/view';
                        return '<tr><td><a href="' + href + '">'+d.label+'</a></td></tr>'
                    })
                );
                if (cdata.offset == -1) { // final page was requested and returned
                    cdata.to     = cdata.total;
                    cdata.offset = cdata.total - rows.length;
                } else if (cdata.offset == -2) { // all rows were returned
                    cdata.to     = cdata.total;
                    cdata.offset = 0;
                } else {
                    cdata.to = cdata.offset + rows.length;
                }
                cdata.from = cdata.offset + 1;
                var newNumbers = cdata.from + ' to ' + cdata.to + ' of ' + cdata.total;
                $('span.numbers', $fldset).text(newNumbers);
                enable_buts($fldset);
             })
             .fail(ajaxerror)
        });
        enable_buts($fldset);
    });
    $('fieldset,legend', 'div#tablesbody.del').addClass('ui-state-highlight');
}

$(init);

