#!/bin/sh
# TODO: Upgrade to dual-view using vlm mosaic
# Add -vv option to debug transcoder or device issues
if [ "$1" == "1" ]; then
  DEV="USB Video Device #1" 
  PORT=8091
  echo "DEV $DEV on port $PORT"
else
  DEV="USB Video Device" 
  PORT=8090
  echo "DEV $DEV on port $PORT"
fi

"/cygdrive/c/Program Files/VideoLAN/VLC/vlc" -vv -I rc \
 dshow:// :dshow-vdev="$DEV" :dshow-size=640x480 \
 --dshow-chroma=MJPG --dshow-fps=30 \
 --dshow-caching=500 \
 :sout="#transcode{vcodec=mp2v,vb=16,fps=30,scale=1,width=320,height=240,acodec=none}:std{access=http,mux=ts,dst=0.0.0.0:$PORT}" \
 --sout-http-mime=application/x-vlc-plugin \
 --sout-http-user="$USER" \
 --sout-http-pwd="$TECANPASSWORD" \
 >./vlc-stream-webcam-$PORT.txt 2>&1

