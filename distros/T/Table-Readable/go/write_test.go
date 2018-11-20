package table_readable

import "testing"

func TestTable(t *testing.T) {
	var table Table
	kv1 := map[string]string{
		"baby": "chops",
		"monty": "baby",
		"nice": "crocodile",
	}
	table = append(table, kv1)
	table.Write()
}
