/*

   Javascript code that maintains a user's lock on an object, and
   checks to ensure that the lock hasn't ben overridden

*/

// From http://developer.apple.com/internet/webcontent/xmlhttpreq.html
var lock_req;
var lock_isIE = false;
var lock_timeout;
var lock_id;

function loadLockReqXML(id) {
    var locking_url = 'remote/locking.cgi?id=' + id;
    lock_id = id;
    // branch for native XMLHttpRequest object
    if (window.XMLHttpRequest) {
        lock_req = new XMLHttpRequest();
        lock_req.onreadystatechange = processLockReqChange;
        lock_req.open("GET", locking_url, true);
        lock_req.send(null);
    // branch for IE/Windows ActiveX version
    } else if (window.ActiveXObject) {
        isIE = true;
        lock_req = new ActiveXObject("Microsoft.XMLHTTP");
        if (lock_req) {
            lock_req.onreadystatechange = processLockReqChange;
            lock_req.open("GET", locking_url, true);
            lock_req.send();
        }
    }

    lock_timeout = setTimeout("loadLockReqXML(" + id + ")", 2000);
}


// handle onreadystatechange event of lock_req object
function processLockReqChange() {

    try{
        // only if req shows "loaded"
        if (lock_req.readyState == 4) {
            // only if "OK"
            if (lock_req.status == 200 || lock_req.status==0 || typeof(lock_req.status)=="undefined") {
                verifyLock();
            }
        }
    }catch(e){
        // what do we do here?
    }
}

// Notify the user if 
function verifyLock() {
    lock = lock_req.responseXML.getElementsByTagName('lock');

    var lock_valid;
    if (lock_isIE) {
        lock_valid = lock_req.responseXML.selectSingleNode('//lock/').getAttribute('valid');

    } else {
        lock_valid = lock[0].getAttribute('valid');
    }

    if (lock_valid == 'false') {
        clearTimeout(lock_timeout);
        lock_req = 0;
        //alert('You have lost your editing lock, ID #'+ lock_id + '. Please tell Miles what you were doing when you got this message!');
    }
}


/*
 * Copyright  1998-2006 Office of Learning Technologies, University of Washington
 * 
 * Licensed under the Educational Community License, Version 1.0 (the "License");
 * you may not use this file except in compliance with the License. You may obtain
 * a copy of the License at: http://www.opensource.org/licenses/ecl1.php
 * 
 * Unless required by applicable law or agreed to in writing, software distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 */
