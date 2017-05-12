function setControl(c) {
    var myForm = document.getElementsByTagName("form")[0]
    var myNum = myForm.getElementsByTagName("input")[0]
    myNum.value = c
    myForm.submit()
}

function gotoSlide(i) {
    var myForm = document.getElementsByTagName("form")[0]
    var myNum = myForm.getElementsByTagName("input")[1]
    myNum.value = i
    myForm.submit()
}

function nextSlide() {
    setControl('advance')
}

function prevSlide() {
    setControl('goback')
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
    switch(key) {
        case 8: prevSlide(); break
        case 13: nextSlide(); break
        case 32: nextSlide(); break
        case 49: gotoSlide(1); break
        case 113: window.close(); break
        default: //xxx(e.which)
    }
}

function handleMouseDown(e) {
    var button = e.which
    if (button == 1) {
        nextSlide()
    }
    else if (button == 3) {
        alert("You are on slide number $slide_num")
    }
    return false
}

document.onkeypress = handleKey
// document.onmousedown = handleMouseDown
document.onclick = nextSlide
document.ondblclick = prevSlide

