function startSlides() {
    var myForm = document.getElementsByTagName("form")[2]
    var mySize = myForm.getElementsByTagName("select")[0]
    var myPage = myForm.getElementsByTagName("input")[2]
    var width = ""
    var height = ""
    var fullscreen = "no"
    switch(mySize.value) {
        case "640x480": width = "640"; height = "480"; break
        case "800x600": width = "800"; height = "600"; break
        case "1024x768": width = "1024"; height = "768"; break
        case "1280x1024": width = "1280"; height = "1024"; break
        case "1600x1200": width = "1600"; height = "1200"; break
        case "fullscreen": fullscreen = "yes"; break
    }
    myUrl = "index.cgi?action=slides&page_id=" + myPage.value
    myArgs = "fullscreen=" + fullscreen + ",height=" + height + ",width=" + width + ",location=no,menubar=no,scrollbars=yes,toolbar=no,resizable=no,titlebar=no"
    myTarget = "SlideShow"
    newWindow = open(myUrl, myTarget, myArgs)
    newWindow.focus()
}
