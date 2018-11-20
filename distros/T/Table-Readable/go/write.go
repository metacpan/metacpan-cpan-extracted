package table_readable

import (
	"fmt"
	"io/ioutil"
	"os"
)

type Table []map[string]string

func (table *Table) Write(fileName string) (err error) {
	f, err := os.Create(fileName)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error opening %s: %s.\n", fileName, err)
		return err
	}
	defer f.Close()
	for _, entry := range *table {
		for key, value := range entry {
			fmt.Fprintf("%%%%%s:\n%s\n%%%%\n\n", key, value)
		}
		fmt.Fprintf("\n")
	}
}

func ReadFile(fileName string) (table *Table, err error) {
	data, err := ioutil.ReadFile(fileName)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading %s: %s.\n", fileName, err)
		return nil, err
	}
	i := 0
	line_start := true
	multi_line := false
	have_key := false
	var key string
	var value string
	kv := make(map[string]string)
	for i < len(data) {
		b := data[i]
		if b == ":" {
			if line_start {
				return nil, errors.New("colon at start of line")
			}
		}
		if line_start && b == "%" {
			i++
			b = data[i]
			if b != "%" {
				// Not a multi-line escape.
			}
		}
		if line_start && b == "\n" {
			// Add the current value
			table = append(table, kv)
			kv = nil
			// Jump over any further empty lines
			for data[i] == "\n" {
				i++
			}
			// Pop the last non-\n character.
			i--
		}
		if b == "\n" {
			line_start = true
		} else {
			line_start = false
		}
		i++
	}
	if kv != nil {
		table = append(table, kv)
	}
	return table, nil
}
