// testenv starts a minimal Tailscale test environment: a testcontrol server,
// a DERP relay server, and a STUN server. It outputs a JSON config to stdout
// and waits for SIGTERM or SIGINT.
package main

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"os"
	"os/signal"
	"syscall"

	"tailscale.com/derp/derpserver"
	"tailscale.com/net/stun"
	"tailscale.com/tailcfg"
	"tailscale.com/tstest/integration/testcontrol"
	"tailscale.com/types/key"
	"tailscale.com/types/logger"
	"tailscale.com/types/nettype"
)

type Config struct {
	ControlURL string `json:"control_url"`
	AuthKey    string `json:"auth_key"`
}

func main() {
	logf := log.Printf
	ipAddr := "127.0.0.1"

	// 1. Start DERP server.
	derpKey := key.NewNode()
	derpSrv := derpserver.New(derpKey, logf)

	derpLn, err := net.Listen("tcp", net.JoinHostPort(ipAddr, "0"))
	if err != nil {
		log.Fatalf("DERP listen: %v", err)
	}

	derpHTTPS := httptest.NewUnstartedServer(derpserver.Handler(derpSrv))
	derpHTTPS.Listener.Close()
	derpHTTPS.Listener = derpLn
	derpHTTPS.Config.ErrorLog = logger.StdLogger(logf)
	derpHTTPS.Config.TLSNextProto = make(map[string]func(*http.Server, *tls.Conn, http.Handler))
	derpHTTPS.StartTLS()

	derpPort := derpLn.Addr().(*net.TCPAddr).Port
	logf("DERP server listening on %s:%d", ipAddr, derpPort)

	// 2. Start STUN server.
	stunConn, err := nettype.Std{}.ListenPacket(context.Background(), "udp4", ":0")
	if err != nil {
		log.Fatalf("STUN listen: %v", err)
	}
	stunAddr := stunConn.LocalAddr().(*net.UDPAddr)
	logf("STUN server listening on %s", stunAddr)
	go runSTUN(stunConn)

	// 3. Build DERP map.
	derpMap := &tailcfg.DERPMap{
		Regions: map[int]*tailcfg.DERPRegion{
			1: {
				RegionID:   1,
				RegionCode: "test",
				Nodes: []*tailcfg.DERPNode{
					{
						Name:             "t1",
						RegionID:         1,
						HostName:         ipAddr,
						IPv4:             ipAddr,
						IPv6:             "none",
						STUNPort:         stunAddr.Port,
						DERPPort:         derpPort,
						InsecureForTests: true,
						STUNTestIP:       ipAddr,
					},
				},
			},
		},
	}

	// 4. Start testcontrol server.
	authKey := "test-auth-key"
	control := &testcontrol.Server{
		Logf:           logger.WithPrefix(logf, "control: "),
		DERPMap:        derpMap,
		RequireAuthKey: authKey,
	}
	controlHTTP := httptest.NewUnstartedServer(control)
	controlHTTP.Start()

	controlURL := controlHTTP.URL
	logf("Control server listening on %s", controlURL)

	// 5. Output JSON config to stdout.
	config := Config{
		ControlURL: controlURL,
		AuthKey:    authKey,
	}
	enc := json.NewEncoder(os.Stdout)
	if err := enc.Encode(config); err != nil {
		log.Fatalf("JSON encode: %v", err)
	}

	// 6. Wait for signal.
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGTERM, syscall.SIGINT)
	sig := <-sigCh
	fmt.Fprintf(os.Stderr, "Received %v, shutting down\n", sig)

	controlHTTP.Close()
	derpHTTPS.CloseClientConnections()
	derpHTTPS.Close()
	derpSrv.Close()
	stunConn.Close()
}

func runSTUN(pc net.PacketConn) {
	var buf [64 << 10]byte
	for {
		n, addr, err := pc.ReadFrom(buf[:])
		if err != nil {
			return
		}
		pkt := buf[:n]
		if !stun.Is(pkt) {
			continue
		}
		txid, err := stun.ParseBindingRequest(pkt)
		if err != nil {
			continue
		}
		udpAddr := addr.(*net.UDPAddr)
		addrPort := netip.AddrPortFrom(udpAddr.AddrPort().Addr(), udpAddr.AddrPort().Port())
		resp := stun.Response(txid, addrPort)
		pc.WriteTo(resp, addr)
	}
}
