function setProtected(self) {
    if (self.checked) {
        var myForm = document.getElementsByTagName("form")[2]
        myForm.getElementsByTagName("input")[6].checked = true
    }
}

function setForDelete(self) {
    if (self.checked) {
        var myForm = document.getElementsByTagName("form")[2]
        myForm.getElementsByTagName("input")[5].checked = false
        myForm.getElementsByTagName("input")[6].checked = false
        myForm.getElementsByTagName("input")[7].checked = false
        myForm.getElementsByTagName("input")[8].checked = false
    }
}
