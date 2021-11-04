#!/usr/local/bin/python3

# This script uses the MISP REST API via the Python module and is
# helpful for seeing the actual JSON and attributes for REST calls.

import json
from pymisp import ExpandedPyMISP, MISPEvent
from pymisp.tools import GenericObjectGenerator
from base64 import b64decode
from io import BytesIO
import os
from datetime import date, datetime
from dateutil.parser import parse

# Show all HTTP calls as debug so we can inspect the JSON
import http.client as http_client
http_client.HTTPConnection.debuglevel = 1

import logging
logger = logging.getLogger('pymisp')
logger.setLevel(logging.DEBUG)

requests_log = logging.getLogger("requests.packages.urllib3")
requests_log.setLevel(logging.DEBUG)
requests_log.propagate = True

misp_url = '[your misp url]'
misp_key = '[your key]' # The MISP auth key can be found on the MISP web interface under the automation section
misp_verifycert = False

def create_new_event():
    me = MISPEvent()
    me.info = "Testing"
    me.add_tag("Tag")
    start = datetime.now()
    me.add_attribute('datetime', start.isoformat(), comment='Start Time')
    return me

pymisp = ExpandedPyMISP(misp_url, misp_key, misp_verifycert, debug=True)
event_id = -1
me = None

me = create_new_event()

misp_object = GenericObjectGenerator('rtir')
misp_object.generate_attributes(json.loads('[{"ticket-number": "3", "subject": "testing", "ip":"1.2.3.4"}]'))


if me:
#    me.add_object()
    event = pymisp.add_event(me)
    r = pymisp.add_object(event, misp_object)
