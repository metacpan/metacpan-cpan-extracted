#!/usr/bin/python
# -*- coding: iso-8859-15 -*-

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Docker_is.py - python FullAuto Instruction Set using FullAuto API.
#    Copyright © 2016-2017  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or
#    modify it under the terms of the GNU Affero General Public License
#    as published by the Free Software Foundation, either version 3 of
#    the License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty
#    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public
#    License along with this program.  If not, see:
#    <http://www.gnu.org/licenses/agpl.html>.
#
#######################################################################

from urllib.parse import urlencode
import httplib2
import argparse
import re
import sys
import getpass
import os
import os.path
import json
import socket
import time
try:
    # For c speedups
    from simplejson import loads, dumps
except ImportError:
    from json import loads, dumps

parser = argparse.ArgumentParser(description=
   'Python Docker ISet using FullAuto API.')
parser.add_argument('clientid')
parser.add_argument('pem_file',nargs='?',default='fullauto.pem')
args=parser.parse_args()
client_id = args.clientid;

# https://web.archive.org/web/20160316113959/http://mancoosi.org/~abate/upload-file-using-httplib 
def upload(url,filename,bearer):
    def encode (file_path, fields=[]):
        BOUNDARY = '----------bundary------'
        CRLF = '\r\n'
        body = []
        # Add the metadata about the upload first
        for key, value in fields:
            body.extend(
              ['--' + BOUNDARY,
               'Content-Disposition: form-data; name="%s"' % key,
               '',
               value,
               ])
        # Now add the file itself
        file_name = os.path.basename(file_path)
        f = open(file_path)
        file_content = f.read()
        f.close()
        body.extend(
          ['--' + BOUNDARY,
           'Content-Disposition: form-data; name="file"; filename="%s"'
           % file_name,
           # The upload server determines the mime-type, no need to set it.
           'Content-Type: application/octet-stream',
           '',
           file_content,
           ])
        # Finalize the form body
        body.extend(['--' + BOUNDARY + '--', ''])
        # https://arstechnica.com/civis/viewtopic.php?t=202651
        return 'multipart/form-data; boundary=%s' % BOUNDARY, CRLF.join(body)

    if os.path.exists(filename):
        print ("UPLOADING: "+filename)
        content_type, body = encode(filename)
        headers = { 'Content-Type': content_type,'Authorization': bearer }
        httpx = httplib2.Http(disable_ssl_certificate_validation=True)
        print (body)
        output=httpx.request(url,'POST', body, headers)
        print (output)
        print ("\n   Waiting for 3 seconds . . .\n")
        time.sleep( 3 )

pem_file_path='';
from os.path import expanduser
home = expanduser("~")
cwd = os.getcwd()
username = getpass.getuser()
if os.path.isfile(args.pem_file) and os.access(args.pem_file, os.R_OK):
    print ("CWD="+cwd)
    pem_file_path=cwd+'/'+args.pem_file
    os.chmod(pem_file_path,0o777)
    print (pem_file_path+" exists and is readable")
elif os.path.isfile(home+'/'+args.pem_file) and \
       os.access(home+'/'+args.pem_file, os.R_OK):
    pem_file_path=home+'/'+args.pem_file
    os.chmod(pem_file_path,0o777)
    print (pem_file_path+" exists and is readable")
elif os.path.isfile('/cygdrive/c/Users/'+username+'/Desktop/'+args.pem_file) \
       and os.access('/cygdrive/c/Users/'+username+'/Desktop/'+args.pem_file, \
       os.R_OK):
    pem_file_path='/cygdrive/c/Users/'+username+'/Desktop/'+args.pem_file
    os.chmod(pem_file_path,0o777)
    print (pem_file_path+"\nexists and is readable")
else:
    print (args.pem_file+" is missing or is not readable")
    sys.exit()
with open(pem_file_path) as f:
    pemfile = f.read()
print (pemfile)

http = httplib2.Http(disable_ssl_certificate_validation=True)
http.follow_redirects = False
url = "http://localhost/request?client_id=" + client_id \
      + "&response_type=code&redirect_uri=/cmd"
print ("URL="+url)
headerz, content = http.request(url, "GET")
print (content)
code = re.search('code=(\d+)',content.decode('utf-8'))
code = code.group(1)
url = "http://localhost//token?grant_type=authorization_code&client_id=" \
      + client_id + "&redirect_uri=/cmd&code=" + code
headerz, content = http.request(url, "GET")
accesstoken = re.search('access_token":(\d+)',content.decode('utf-8'))
accesstoken = accesstoken.group(1);
refreshtoken = re.search('refresh_token":(\d+)',content.decode('utf-8'))
refreshtoken = refreshtoken.group(1);
credentials_file = 'credentials.csv'
if os.path.isfile(credentials_file) and os.access(credentials_file, os.R_OK):
    cred_file_path=cwd+'/'+credentials_file
    os.chmod(cred_file_path,0o777)
    print (cred_file_path+" exists and is readable")
elif os.path.isfile(home+'/'+credentials_file) and \
       os.access(home+'/'+credentials_file, os.R_OK):
    cred_file_path=home+'/'+credentials_file
    os.chmod(cred_file_path,0o777)
    print (cred_file_path+" exists and is readable")
elif os.path.isfile('/cygdrive/c/Users/'+username+'/Desktop/'+ \
       credentials_file) and os.access('/cygdrive/c/Users/'+username+ \
       '/Desktop/'+credentials_file, os.R_OK):
    cred_file_path='/cygdrive/c/Users/'+username+'/Desktop/'+credentials_file
    os.chmod(cred_file_path,0o777)
    print (cred_file_path+"\nexists and is readable")
else:
    print (credentials_file+" is missing or is not readable")
    sys.exit()
bearer  = "Bearer "+accesstoken
url = 'http://localhost/cmd'
upload(url,cred_file_path,bearer)
#sys.exit()
with open("/tmp/"+credentials_file) as f:
    for line in f:
        items=line.split(',');
#data = {'cmd': [['aws_configure',items[1],items[2]],
data = {'cmd': [['cmd','hostname'],
                ['cwd','/bin'],
                ['cmd_raw','export HELLO=hello'],
                ['cmd','echo $HELLO'],
                ['cmd','pwd'],
                ['cmd','aws ec2 describe-instances']]}
headers = {'Content-Type': 'application/json','Authorization': bearer }
url     = 'http://localhost/cmd'
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
result = json.loads(result[5][0])
myip=([l for l in ([ip for ip in socket.gethostbyname_ex(socket.gethostname())[2] \
     if not ip.startswith("127.")][:1], [[(s.connect(('8.8.8.8', 53)), \
     s.getsockname()[0], s.close()) for s in [socket.socket(socket.AF_INET, \
     socket.SOCK_DGRAM)]][0][1]]) if l][0][0])
for inst in result['Reservations']:
   print (inst)
   for elem in inst['Instances']:
      print (elem)
      if elem['State']['Name'] == 'terminated':
            print ("GOT CONTINUE")
            continue
      if myip == elem['PrivateIpAddress']:
            print (elem['SecurityGroups'][0]['GroupId'])
            print (elem['PrivateIpAddress'])
            print (elem['State']['Name'])
            print (elem['SubnetId'])
            break
   else:
      continue
   break
print ("\n   Waiting for 3 seconds . . .\n")
time.sleep( 3 )
gid      = elem['SecurityGroups'][0]['GroupId']
sid      = elem['SubnetId']
headers  = {'Content-Type': 'application/json','Authorization': bearer }
dsg      = 'aws ec2 describe-security-groups'
data     = {'cmd':[['cmd',dsg]]};
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
result = json.loads(result[0][0])
print (result)
cidr=''
dockergid=''
for inst in result['SecurityGroups']:
   print (inst)
   dockergid = inst['GroupId']
   try:
      cidr      = inst['IpPermissions'][0]['IpRanges'][0]['CidrIp']
   except IndexError:
      cidr      = ''
   if gid == inst['GroupId']:
      break
new_sg   = 'aws ec2 create-security-group --group-name ' + \
           'DockerSecurityGroup --description ' + \
           '"Docker.com Security Group" 2>&1';
ingress  = 'aws ec2 authorize-security-group-ingress ' + \
           '--group-name DockerSecurityGroup --protocol tcp ' + \
           '--port 22 --cidr ' + cidr + ' 2>&1'

print (ingress)

print ("\n   Waiting for 3 seconds . . .\n")
time.sleep( 3 )

upload(url,pem_file_path,bearer)

print ("Done with Upload")
#sys.exit()

time.sleep( 1 )

data = {'cmd': [['cmd','echo $HOME'],
                ['cmd','echo $USER'],
                ['cmd','echo $HOSTNAME'],
                ['cmd','mkdir -pv $HOME/FullAutoAPI']]}
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
homedir=result[0][0]
remuser=result[1][0]
hostnam=result[2][0]
lochost=socket.gethostname()

if hostnam == lochost:
   remuser=username
   homedir=home

time.sleep( 1 )

mvpem=args.pem_file
if re.search(' ',args.pem_file):
    mvpem="'"+mvpem+"'"
mvcre=credentials_file
if re.search(' ',args.pem_file):
    mvcre="'"+mvcre+"'"
    
data = {'cmd': [['cmd','sudo mv -vf /tmp/'+mvpem+
                 ' '+homedir+'/FullAutoAPI'],
                ['cmd','sudo mv -vf /tmp/'+mvcre+
                 ' '+homedir+'/FullAutoAPI'],
                ['cwd',homedir+'/FullAutoAPI'],
                ['cmd','chmod -v 400 '+mvpem],
                ['cmd',new_sg],
                ['cmd',ingress]]}
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
from pprint import pprint
sec_group_id=''
if re.search('already exists for VPC',result[4][0]):
   get_sec='aws ec2 describe-security-groups --group-names DockerSecurityGroup'
   data = {'cmd': [['cmd',get_sec]]}
   time.sleep( 1 )
   headerz, content = http.request(url, "POST", body=dumps(data), \
      headers=headers)
   result = json.loads(content)
   result = json.loads(result['result'])
   result = json.loads(result[0][0])
   sec_group_id = result['SecurityGroups'][0]['GroupId']
else:
   result=json.loads(result[4][0])
   sec_group_id=result['GroupId']
time.sleep( 1 )
print ("   Continuing . . .\n")
#sys.exit()
region = "sudo wget -qO- http://169.254.169.254/latest/dynamic/instance-identity/document|grep region"
data = {'cmd': [['cmd',region]]}
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
region=re.search(': "(.+)"',result[0][0]).group(1)
time.sleep(1)
get_inst = 'aws ec2 describe-images --owners self amazon --filters "Name=root-device-type,Values=ebs" "Name=virtualization-type,Values=hvm" "Name=architecture,Values=x86_64" "Name=block-device-mapping.volume-size,Values=8" "Name=block-device-mapping.volume-type,Values=gp2" "Name=state,Values=available" --region='+region
data = {'cmd': [['cmd',get_inst]]}
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
result = json.loads(result[0][0])
imagid = result['Images'][0]['ImageId']
keynam = re.sub(r' [(]\d+[)]','',args.pem_file)
keynam = re.sub(r'\.pem$','',keynam)
new_inst = 'aws ec2 run-instances --image-id '+imagid+' --count=1 ' + \
           '--key-name ' + keynam + ' ' + \
           '--instance-type=t2.micro --security-group-ids ' + \
           sec_group_id + ' --subnet-id ' + sid
data = {'cmd': [['cmd',new_inst]]}
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
result = json.loads(result[0][0])
docker_ip=result['Instances'][0]['PrivateIpAddress']
instance_id=result['Instances'][0]['InstanceId']
loop = 1
while loop == 1: # This creates an infinite loop
   time.sleep( 1 )
   data = {'cmd': [['cmd','aws ec2 describe-instances --instance-ids '+instance_id+' 2>&1']]};
   headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
   result = json.loads(content)
   result = json.loads(result['result'])
   result = json.loads(result[0][0])
   print ('------------------')
   print (result['Reservations'][0]['Instances'][0]['State']['Name'])
   if result['Reservations'][0]['Instances'][0]['State']['Name'] == 'running':
      break
print ('===================')
print (docker_ip)
print ("USERNAME/PEMFILE="+remuser+'/'+args.pem_file)
data = {'cmd': [['connect_secure',{'ip':docker_ip,'login':'ec2-user','identityfile':'/home/'+remuser+'/FullAutoAPI/'+args.pem_file,'noretry':'1'}]]}
time.sleep( 1 )
docker_server1='';
print ("\nGoing to Attempt to Connect to new Docker Server via ssh . . .\n")
while loop == 1: # This creates an infinite loop
   headerz, content = http.request(url, "POST", body=dumps(data), \
      headers=headers)
   result = json.loads(content)
   result = json.loads(result['result'])
   if re.search('Connection timed out|Connection refused',result[0][1]):
      print ("\n   Waiting for sshd service to start . . .\n")
      time.sleep( 3 )
      continue
   else:
      print ("GOT DOCKER!!!!"+result[0][1])
      docker_server1=result[0][0]
   break
time.sleep( 1 )
print ("DOCKER_SERVER1="+docker_server1)
data = {'cmd': [['label',[docker_server1,'cmd','sudo yum -y install docker docker-registry']],
                ['label',[docker_server1,'cmd','sudo service docker start']],
                ['label',[docker_server1,'cmd','sudo usermod -a -G docker ec2-user']]]}
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
print (result[0][1])
time.sleep( 1 )
data = {'cmd': [['label',[docker_server1,'close']]]}
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
print (result)
print ("USERNAME="+remuser+'/'+args.pem_file)
data = {'cmd': [['connect_secure',{'ip':docker_ip,'login':'ec2-user', \
   'identityfile':'/home/'+remuser+'/FullAutoAPI/'+
   args.pem_file,'noretry':'1'}]]}
time.sleep( 1 )
docker_server1='';
while loop == 1: # This creates an infinite loop
   print ("GOING FOR CONNECT")
   headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
   result = json.loads(content)
   result = json.loads(result['result'])
   if re.search('Connection timed out|Connection refused',result[0][1]):
      print (result[0][1])
      time.sleep( 1 )
      continue
   else:
      print ("GOT DOCKER AGAIN!!!!")
      docker_server1=result[0][0]
   break
time.sleep( 1 )
print ("DOCKER_SERVER1="+docker_server1)
data = {'cmd': [['label',[docker_server1,'cmd','hostname']]]}
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
print ("HOSTNAME="+str(result[0][0]))
time.sleep( 1 )
data = {'cmd': [['label',[docker_server1,'cmd','docker info']]]}
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
print ("DOCKER INFO="+str(result[0][0]))
time.sleep( 1 )
data = {'cmd': [['label',[docker_server1,'docker_run','ubuntu /bin/bash']]]}
headerz, content = http.request(url, "POST", body=dumps(data), headers=headers)
result = json.loads(content)
result = json.loads(result['result'])
print ("DOCKER CONTAINER HOSTNAME="+str(result[0][0]))
