function gotoPage(page_id) {
    var url = "index.cgi?" + page_id
    document.location = url;
}

function editPage() {
    var myForm = document.getElementsByTagName("form")[2]
    myForm.submit()
}

function savePage() {
    var myForm = document.getElementsByTagName("form")[2]
    var mySave = myForm.getElementsByTagName("input")[2]
    mySave.checked = true
    myForm.submit()
}

function previewPage() {
    var myForm = document.getElementsByTagName("form")[2]
    var myPreview = myForm.getElementsByTagName("input")[3]
    myPreview.focus()
    myForm.submit()
}

function handleKey(e) {
    var key;
    if (e == null) {
        // IE
        key = event.keyCode
    } 
    else {
        // Mozilla
        if (e.altKey || e.ctrlKey) {
            return true
        }
        key = e.which
    }
    letter = String.fromCharCode(key).toLowerCase();
    switch(letter) {
        case "t": gotoPage(top_page); break
        case "?": gotoPage('KwikiHotKeys'); break
        case "h": gotoPage('KwikiHelpIndex'); break
        case "e": editPage(); break
        case "s": savePage(); break
        case "p": previewPage(); break
    }
}

document.onkeypress = handleKey
